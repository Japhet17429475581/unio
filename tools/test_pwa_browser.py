"""Local Chrome smoke test: no real API, users, university or analytics requests."""
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import re
from pathlib import Path
import shutil
import threading
from urllib.parse import urlparse

from playwright.sync_api import sync_playwright, expect

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'build/pwa-smoke-site'


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


def main():
    shutil.copytree(ROOT / 'build/web', SITE, dirs_exist_ok=True)
    server = ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(Handler, directory=str(SITE)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    origin = f'http://localhost:{server.server_port}'
    with sync_playwright() as p:
        browser = p.chromium.launch(channel='chrome', headless=True)
        context = browser.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=1, reduced_motion='reduce')
        context.add_init_script("localStorage.setItem('flutter.dark_mode', 'true')")
        external = []
        registered = []
        deleted = []
        portal_calls = []
        portal_logins = []
        assistant_calls = []

        def route_request(route):
            url = route.request.url
            if url.startswith(origin + '/api/v1/web-push/config'):
                route.fulfill(content_type='application/json', body='{"enabled":false}')
            elif url.startswith(origin + '/api/v1/web-portal/'):
                path = urlparse(url).path
                status, data = 200, {'success': True}
                if path.endswith('/login'):
                    portal_logins.append(route.request.post_data_json)
                    data = {'account_token': 'synthetic-web-token', 'group': 'TEST-101'}
                elif path.endswith('/request'):
                    payload = route.request.post_data_json
                    portal_calls.append(payload)
                    target = payload['path']
                    if '/progress/index' in target:
                        source = '''<div class="AcademicProgress"><div class="AcademicProgress-Semester"><h3>2 семестр</h3><table>
                        <tr><td class="AcademicProgress-Subject">Тестовая дисциплина</td>
                        <td class="AcademicProgress-Result"><div class="tdItem">91</div><div class="tdItem">зачтено</div></td></tr>
                        <tr><td class="AcademicProgress-Subject">Современный русский язык</td>
                        <td class="AcademicProgress1"><div class="tdItem">19</div><div class="tdItem">0</div></td>
                        <td class="AcademicProgress2"><div class="tdItem">54</div><div class="tdItem">2</div></td>
                        <td class="AcademicProgress3"><div class="tdItem">60</div><div class="tdItem">2</div></td>
                        <td class="AcademicProgress-Result"><div class="tdItem">91</div><div class="tdItem">хорошо</div></td></tr>
                        </table></div></div>'''
                    else:
                        source = '''<select id="category-selector"><option value="4">Обучение</option></select>
                        <div class="list-view"><div class="requestItem" data-key="101">
                        <a href="/request/101/edit"><h3 class="requestItem-title">Тестовая справка</h3>
                        <div class="Ach-Status pre">получение информации</div></a></div></div>'''
                    data = {'status': 200, 'data': '<form action="/auth/logout"></form>' + source,
                            'url': target, 'content_type': 'text/html; charset=utf-8'}
                route.fulfill(status=status, content_type='application/json', body=json.dumps(data))
            elif url.startswith(origin + '/'):
                route.continue_()
            elif urlparse(url).hostname == 'bot-1790421609-9641-larisfonkraft.bothost.tech':
                path = urlparse(url).path
                headers = {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': '*',
                           'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'}
                status = 200
                data = {}
                if route.request.method == 'OPTIONS':
                    status = 204
                elif path.endswith('/groups'): data = {'groups': ['TEST-101']}
                elif path.endswith('/auth/guest'):
                    registered.append(route.request.post_data_json)
                    data = {'account_token': 'synthetic-web-token'}
                elif path.endswith('/auth/me'): data = {'mode': 'guest', 'group_code': 'TEST-101'}
                elif path.endswith('/auth/account'):
                    deleted.append(True)
                    status = 204
                elif path.endswith('/auth/consents'): status = 204
                elif path.endswith('/assistant/message'):
                    payload = route.request.post_data_json
                    assistant_calls.append(payload)
                    if 'расписание' in payload['question'].lower() or 'первая пара' in payload['question'].lower():
                        data = {'status': 'schedule', 'date':'2026-10-26', 'group':'TEST-101', 'lessons':[
                            {'date':'2026-10-26','start':'09:40','end':'11:10','subject':'Тестовая пара','teacher':'Преподаватель','room':'101','group':'TEST-101'}]}
                    elif 'новост' in payload['question'].lower():
                        data = {'status':'news','date':'2026-10-21','items':[{
                            'id':42,'title':'Новость университета','description':'Тестовое описание',
                            'content':'Текст новости из базы UNIO.','content_truncated':False,
                            'image_url':'https://www.vspu.ru/__unio_synthetic_news.png',
                            'source_url':'https://www.vspu.ru/news/42','published_at':'2026-10-21T12:00:00+03:00'
                        }],'has_more':False}
                    elif 'справку' in payload['question'].lower():
                        data = {'status':'requests_help','action':'open_requests'}
                    else:
                        data = {'status':'answered','claims':[{'text':'Условия назначения указаны в документе.', 'evidence':[{'source_id':'S1','quote':'Синтетическая цитата для проверки интерфейса.'}]}],
                                'sources':[{'source_id':'S1','document_id':'a'*64,'title':'Положение о стипендиальном обеспечении','page':13,'locator':'PDF page 13','source_url':'https://www.vspu.ru/document/3816'}]}
                elif path.endswith('/schedule'): data = {'lessons': []}
                elif path.endswith('/news'): data = {'items': []}
                if path.endswith('/assistant/message') and route.request.method == 'POST':
                    body='event: status\ndata: {"status":"searching"}\n\n'
                    if data.get('status')=='answered':
                        body+='event: partial\ndata: '+json.dumps(data)+'\n\n'
                    body+='event: result\ndata: '+json.dumps(data)+'\n\n'
                    route.fulfill(status=status,content_type='text/event-stream',headers=headers,body=body)
                else:
                    route.fulfill(status=status, content_type='application/json', headers=headers,
                                  body='' if status == 204 else json.dumps(data))
            elif url == 'https://www.vspu.ru/__unio_synthetic_news.png':
                route.fulfill(status=200,content_type='image/png',body=(ROOT/'web/icons/Icon-192.png').read_bytes())
            else:
                external.append(url.split('?')[0])
                route.abort()

        context.route('**/*', route_request)
        page = context.new_page()
        errors = []
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.on('console', lambda message: print('browser:', message.type, message.text[:250], flush=True) if message.type == 'error' else None)
        page.goto(origin,wait_until='domcontentloaded',timeout=60000)
        print('page loaded', flush=True)
        page.wait_for_selector('flt-glass-pane', state='attached', timeout=45000)
        page.wait_for_selector('#boot', state='detached', timeout=90000)
        page.screenshot(path=str(ROOT / 'build/pwa-mobile.png'))
        print('Flutter started', errors, flush=True)
        print(page.evaluate("navigator.serviceWorker.getRegistrations().then(rs => rs.map(r => ({scope:r.scope, active:r.active?.state, installing:r.installing?.state, waiting:r.waiting?.state})))"), flush=True)
        page.wait_for_function("navigator.serviceWorker.getRegistration().then(r => !!r?.active)", timeout=45000)
        print('worker ready', flush=True)
        page.locator('flt-semantics-placeholder').evaluate('(element) => element.click()')
        page.get_by_role('button', name='Пропустить', exact=True).click()
        page.wait_for_timeout(800)
        page.screenshot(path=str(ROOT / 'build/pwa-entry.png'))
        page.get_by_role('button', name=re.compile(r'^Я студент(?:\s|$)')).click()
        page.get_by_role('button', name=re.compile(r'^Продолжить как гость(?:\s|$)')).click()
        page.get_by_role('textbox', name='Номер группы', exact=False).click()
        page.keyboard.type('TEST-101', delay=60)
        page.keyboard.press('Tab')
        page.get_by_role('button', name='Продолжить', exact=True).click()
        page.wait_for_timeout(1000)
        page.screenshot(path=str(ROOT / 'build/pwa-consent.png'))
        terms = page.get_by_role('checkbox', name='Принимаю пользовательское соглашение')
        terms.click()
        expect(terms).to_have_attribute('aria-checked', 'true')
        consent = page.get_by_role('checkbox', name='Даю согласие на обработку персональных данных UNIO', exact=False)
        consent.click()
        expect(consent).to_have_attribute('aria-checked', 'true')
        page.get_by_role('button', name='Продолжить', exact=True).click()
        page.wait_for_timeout(3000)
        page.screenshot(path=str(ROOT / 'build/pwa-home.png'))
        page.get_by_role('tab', name='Настройки', exact=True).wait_for(timeout=30000)
        page.get_by_role('button', name='UNIO AI', exact=True).first.click()
        page.wait_for_timeout(600)
        page.screenshot(path=str(ROOT / 'build/assistant-welcome.png'))
        page.get_by_role('button',name='Какая у меня завтра первая пара?',exact=True).click()
        page.wait_for_timeout(1200)
        page.screenshot(path=str(ROOT / 'build/assistant-schedule.png'))
        print('Assistant synthetic requests:',len(assistant_calls),flush=True)
        page.locator('[aria-label*="Тестовая пара"]').first.wait_for()
        assert assistant_calls[-1]['allow_external'] is False
        page.screenshot(path=str(ROOT / 'build/assistant-schedule.png'))
        page.get_by_role('textbox',name='Сообщение…',exact=True).click()
        page.keyboard.type('Как получить социальную стипендию?', delay=30)
        page.get_by_role('button',name='Отправить',exact=True).click()
        page.get_by_role('button',name='Разрешить и отправить вопрос',exact=True).click()
        # Flutter paints SelectableText on canvas; its disabled semantic textarea
        # has no DOM value. The source control confirms the answered block.
        page.get_by_role('button', name='Источники · 1', exact=True).wait_for()
        assert assistant_calls[-1]['allow_external'] is True
        assert not {'login','password','history','token'} & assistant_calls[-1].keys()
        page.wait_for_timeout(600)
        page.screenshot(path=str(ROOT / 'build/assistant-answer.png'))
        # Encrypted on-device history survives a real page reload.
        page.get_by_role('button',name='История чатов',exact=True).click()
        page.get_by_role('button',name=re.compile(r'^История чатов:')).first.click()
        page.screenshot(path=str(ROOT/'build/assistant-history-menu.png'))
        page.get_by_role('menuitem',name='Переименовать',exact=True).click()
        page.screenshot(path=str(ROOT/'build/assistant-history-rename.png'))
        rename = page.get_by_role('textbox').last
        rename.click()
        page.keyboard.press('Control+a')
        page.keyboard.type('Тестовый разговор')
        page.get_by_role('button',name='Сохранить',exact=True).click()
        page.wait_for_timeout(600)
        page.screenshot(path=str(ROOT/'build/assistant-history.png'))
        search = page.get_by_role('textbox',name='Поиск по перепискам',exact=True)
        search.click()
        page.keyboard.type('нет_такого_разговора_987')
        page.get_by_text('Переписки не найдены',exact=True).wait_for()
        search.click()
        page.keyboard.press('Control+a')
        page.keyboard.type('Условия назначения')
        page.locator('[aria-label*="Тестовый разговор"]:visible').first.wait_for()
        print('History rename and encrypted content search passed',flush=True)
        page.locator('[aria-label*="Тестовый разговор"]:visible').first.click()
        page.get_by_role('button',name='Источники · 1',exact=True).wait_for()
        page.wait_for_timeout(600)
        encrypted = page.evaluate("Object.entries(localStorage).filter(([k])=>k.includes('assistant_history_v1_'))")
        assert encrypted, 'no durable chat entries found'
        assert not any('Условия назначения' in value or 'социальную стипендию' in value for _,value in encrypted), 'plaintext chat in browser storage'
        count_before_restore=len(assistant_calls)
        page.reload(wait_until='domcontentloaded')
        page.wait_for_selector('#boot',state='detached',timeout=90000)
        page.locator('flt-semantics-placeholder').evaluate('(element)=>element.click()')
        page.get_by_role('button',name='UNIO AI',exact=True).first.click()
        page.get_by_role('button',name='Источники · 1',exact=True).wait_for()
        assert len(assistant_calls)==count_before_restore, 'restoring chat called model'
        print('Encrypted history restored after reload without provider call',flush=True)
        page.get_by_role('button',name='Новый чат',exact=True).click()
        page.get_by_text('Чем могу помочь?',exact=True).wait_for()
        page.get_by_role('textbox',name='Сообщение…',exact=True).click()
        page.keyboard.type('Новости за 21 октября 2026',delay=20)
        page.get_by_role('button',name='Отправить',exact=True).click()
        page.locator('[aria-label*="Новость университета"]').first.wait_for()
        assert assistant_calls[-1]['allow_external'] is False
        page.wait_for_timeout(700)
        page.screenshot(path=str(ROOT/'build/assistant-news.png'))
        page.locator('[aria-label*="Новость университета"]').first.click()
        page.get_by_text('Новость университета',exact=True).wait_for()
        page.get_by_role('button',name='Назад',exact=True).click()
        page.get_by_role('textbox',name='Сообщение…',exact=True).click()
        page.keyboard.type('Где можно заказать справку?',delay=20)
        page.get_by_role('button',name='Отправить',exact=True).click()
        page.get_by_role('button',name='Справки и заявления',exact=True).click()
        # UnioCard merges the heading, explanation and sign-in button in semantics.
        page.get_by_role('button',name=re.compile(r'Войти через портал')).wait_for()
        page.screenshot(path=str(ROOT/'build/assistant-requests-guest.png'))
        page.get_by_role('button',name='Назад',exact=True).click()
        page.get_by_role('button',name='UNIO AI',exact=True).first.click()
        page.get_by_role('heading',name='UNIO AI',exact=True).wait_for()
        page.wait_for_timeout(400)
        assistant_count=len(assistant_calls)
        page.get_by_role('textbox',name='Сообщение…',exact=True).click()
        page.keyboard.type('Что у меня по русскому?',delay=20)
        page.get_by_role('button',name='Отправить',exact=True).click()
        page.get_by_role('button',name='Открыть успеваемость',exact=True).click()
        expect(page.get_by_role('tab',name='Успеваемость',exact=True)).to_have_attribute('aria-selected','true')
        page.get_by_role('button',name=re.compile(r'Войти через портал')).wait_for()
        assert len(assistant_calls)==assistant_count, 'guest grade query reached assistant API'
        print('Assistant schedule, consent, sources, encrypted history, rename and restart passed',flush=True)
        assert registered and registered[0]['group_code'] == 'TEST-101'
        assert 'consents' in registered[0] and 'password' not in registered[0] and 'login' not in registered[0]
        print('Guest login and consents passed', flush=True)
        page.get_by_role('tab', name='Настройки', exact=True).click()
        # Language is a persisted UI preference, not a new university session.
        page.mouse.move(180, 620)
        page.mouse.wheel(0, 230)
        page.wait_for_timeout(400)
        page.screenshot(path=str(ROOT / 'build/pwa-language-picker-before.png'))
        page.get_by_role('button', name=re.compile(r'^Язык')).click()
        page.get_by_role('button', name=re.compile(r'^English')).click()
        page.get_by_role('tab', name='Settings', exact=True).wait_for()
        page.get_by_role('tab', name='Grades', exact=True).wait_for()
        assert page.evaluate('document.documentElement.lang') == 'en'
        assert page.locator('#update-now').text_content() == 'Update'
        page.screenshot(path=str(ROOT / 'build/pwa-english-settings.png'))
        page.reload()
        page.wait_for_selector('#boot', state='detached', timeout=90000)
        page.locator('flt-semantics-placeholder').evaluate('(element) => element.click()')
        page.get_by_role('tab', name='Settings', exact=True).click()
        page.mouse.move(180, 620)
        page.mouse.wheel(0, 230)
        page.wait_for_timeout(400)
        page.get_by_role('button', name=re.compile(r'^Language')).click()
        page.get_by_role('button', name=re.compile(r'^Русский')).click()
        page.get_by_role('tab', name='Настройки', exact=True).wait_for()
        assert page.evaluate('document.documentElement.lang') == 'ru'
        assert len(registered) == 1, 'language change created another account'
        page.mouse.wheel(0, -900)
        page.wait_for_timeout(400)
        print('Language switch and restart persistence passed', flush=True)
        page.screenshot(path=str(ROOT / 'build/pwa-before-portal.png'))
        page.mouse.click(195, 342)
        inputs = page.get_by_role('textbox')
        inputs.nth(0).click()
        page.keyboard.type('synthetic-login', delay=15)
        inputs.nth(1).click()
        page.keyboard.type('synthetic-password', delay=15)
        page.get_by_role('button', name='Войти', exact=True).click()
        page.wait_for_timeout(1200)
        page.screenshot(path=str(ROOT / 'build/pwa-portal-result.png'))
        page.get_by_role('tab', name='Успеваемость', exact=True).click()
        page.get_by_text('Тестовая дисциплина', exact=False).wait_for(timeout=30000)
        assert len(portal_logins) == 1
        assert portal_logins[0]['account_token'] == 'synthetic-web-token'
        grade_reads=sum('/progress/index' in call['path'] for call in portal_calls)
        assistant_count=len(assistant_calls)
        page.get_by_role('tab',name='Расписание',exact=True).click()
        page.get_by_role('button',name='UNIO AI',exact=True).first.click()
        page.get_by_role('textbox',name='Сообщение…',exact=True).click()
        page.keyboard.type('Что у меня по русскому?',delay=20)
        page.get_by_role('button',name='Отправить',exact=True).click()
        page.get_by_role('button',name='Открыть успеваемость',exact=True).wait_for()
        # Expanded UnioCard content is exposed through its group aria-label.
        grade_card=page.get_by_role('group',name=re.compile(r'Современный русский язык'))
        grade_card.wait_for()
        assert '54 б.' in grade_card.get_attribute('aria-label')
        assert len(assistant_calls)==assistant_count, 'personal grades reached assistant API'
        assert sum('/progress/index' in call['path'] for call in portal_calls)==grade_reads, 'chat duplicated cached grade fetch'
        page.mouse.move(382,80)
        page.wait_for_timeout(500)
        page.screenshot(path=str(ROOT/'build/assistant-grades.png'))
        page.get_by_role('button',name='Открыть успеваемость',exact=True).click()
        expect(page.get_by_role('tab',name='Успеваемость',exact=True)).to_have_attribute('aria-selected','true')
        page.get_by_text('Тестовая дисциплина',exact=False).wait_for()
        print('Private grade cards, guest gate, shared RAM cache and tab navigation passed',flush=True)
        page.get_by_role('tab', name='Университет', exact=True).click()
        page.get_by_text('Подать заявление', exact=False).last.click()
        page.get_by_text('Тестовая справка', exact=False).wait_for(timeout=30000)
        assert any('/request/index' in call['path'] for call in portal_calls)
        print('Web portal login, gradebook and requests passed', flush=True)
        page.reload()
        page.wait_for_selector('#boot', state='detached', timeout=90000)
        page.locator('flt-semantics-placeholder').evaluate('(element) => element.click()')
        page.get_by_role('tab', name='Успеваемость', exact=True).click()
        page.get_by_text('Тестовая дисциплина', exact=False).wait_for(timeout=30000)
        assert len(portal_logins) == 1, 'restart prompted another university login'
        page.evaluate("""() => new Promise((resolve, reject) => {
          const req = indexedDB.open('unio_lesson_notes', 1);
          req.onupgradeneeded = () => req.result.createObjectStore('files');
          req.onerror = () => reject(new Error('test_note_open_failed'));
          req.onsuccess = () => {
            const db = req.result;
            const tx = db.transaction('files', 'readwrite');
            tx.objectStore('files').put([1, 2, 3], 'synthetic-note');
            tx.oncomplete = () => { db.close(); resolve(true); };
            tx.onerror = () => reject(new Error('test_note_write_failed'));
          };
        })""")
        manifest = page.evaluate("fetch('manifest.json').then(r => r.json())")
        assert manifest['short_name'] == 'UNIO' and manifest['display'] == 'standalone'
        keys = page.evaluate('caches.keys()')
        assert any(key.startswith('unio-shell-') for key in keys)
        page.reload()
        page.wait_for_selector('#boot', state='detached', timeout=90000)
        page.wait_for_function('navigator.serviceWorker.controller !== null')
        # API responses (even same-origin GETs) must not be intercepted by the shell.
        assert page.evaluate("fetch('/api/synthetic').then(r => r.status)") == 404
        cached = page.evaluate("caches.keys().then(async keys => (await Promise.all(keys.map(async k => (await (await caches.open(k)).keys()).map(r => r.url)))).flat())")
        assert not any('/api/' in url or 'portal.vspu.ru' in url for url in cached)
        context.set_offline(True)
        page.reload(wait_until='domcontentloaded')
        page.wait_for_selector('#boot', state='detached', timeout=90000)
        assert page.locator('flt-glass-pane').count() == 1
        page.locator('flt-semantics-placeholder').evaluate('(element) => element.click()')
        offline_assistant_count = len(assistant_calls)
        page.get_by_role('button',name='UNIO AI',exact=True).first.click()
        page.get_by_role('group',name=re.compile(r'Современный русский язык')).wait_for()
        assert len(assistant_calls) == offline_assistant_count, 'reading offline history requested assistant API'
        page.get_by_role('button',name='История чатов',exact=True).click()
        page.get_by_role('button',name='Вернуться к расписанию',exact=True).click()
        page.get_by_role('tab',name='Настройки',exact=True).wait_for()
        print('Offline private history and return navigation passed',flush=True)
        context.set_offline(False)
        page.get_by_role('tab', name='Настройки', exact=True).click()
        page.mouse.move(180, 620)
        page.mouse.wheel(0, 570)
        page.get_by_text('Документы и данные', exact=False).click()
        page.get_by_role('button', name='Отозвать согласие и удалить данные', exact=True).click()
        page.get_by_role('button', name='Удалить', exact=True).click()
        page.get_by_role('button', name=re.compile(r'^Я студент(?:\s|$)')).wait_for(timeout=30000)
        assert deleted, 'server deletion not requested'
        count = page.evaluate("""() => new Promise((resolve, reject) => {
          const req = indexedDB.open('unio_lesson_notes', 1);
          req.onsuccess = () => {
            const db = req.result;
            const tx = db.transaction('files', 'readonly');
            const count = tx.objectStore('files').count();
            tx.oncomplete = () => { db.close(); resolve(count.result); };
            tx.onerror = reject;
          };
          req.onerror = reject;
        })""")
        assert count == 0, 'local note remained after deletion'
        assert page.evaluate("Object.keys(localStorage).filter(k=>k.includes('assistant_history_v1_')).length") == 0, 'local chat remained after deletion'
        print('Browser account and note deletion passed', flush=True)

        # Only the isolated test copy changes. The distributable build stays intact.
        worker = SITE / 'unio-sw.js'
        content = worker.read_text(encoding='utf8')
        metadata = json.loads((SITE / 'pwa-build.json').read_text(encoding='utf8'))
        worker.write_text(content.replace(metadata['web_build'], metadata['web_build'] + '-test-update'), encoding='utf8')
        page.evaluate('navigator.serviceWorker.getRegistration().then(r => r.update())')
        page.wait_for_selector('#update', state='visible', timeout=90000)
        assert page.locator('flt-glass-pane').count() == 1
        page.click('#update-later')
        assert page.locator('#update').is_hidden()
        # Make the same already-waiting update visible again, then explicitly accept it.
        page.evaluate("document.getElementById('update').hidden = false")
        page.click('#update-now')
        page.wait_for_function("navigator.serviceWorker.controller && document.getElementById('update').hidden", timeout=90000)
        page.wait_for_selector('#boot', state='detached', timeout=90000)
        page.set_viewport_size({'width': 1440, 'height': 900})
        page.screenshot(path=str(ROOT / 'build/pwa-desktop.png'))
        assert not errors, errors
        assert not external, external
        print(json.dumps({'boot': True, 'offline_restart': True, 'update': True,
                          'api_not_cached': True, 'guest_login': True, 'portal_login': True,
                          'gradebook': True, 'requests': True, 'persistent_login': True,
                          'deletion': True, 'external_requests': len(external),
                          'page_errors': len(errors), 'manifest': manifest['short_name'],
                          'locale_switch': True, 'locale_persistence': True}))
        browser.close()
    server.shutdown()


if __name__ == '__main__':
    main()
