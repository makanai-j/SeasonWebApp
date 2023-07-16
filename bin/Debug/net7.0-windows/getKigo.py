import requests
import re
import json

urlDict = {"spring":"https://ja.wikipedia.org/wiki/Category:%E6%98%A5%E3%81%AE%E5%AD%A3%E8%AA%9E",
           "summer":"https://ja.wikipedia.org/wiki/Category:%E5%A4%8F%E3%81%AE%E5%AD%A3%E8%AA%9E",
           "autumn":"https://ja.wikipedia.org/wiki/Category:%E7%A7%8B%E3%81%AE%E5%AD%A3%E8%AA%9E",
           "winter":"https://ja.wikipedia.org/wiki/Category:%E5%86%AC%E3%81%AE%E5%AD%A3%E8%AA%9E"}

crArray = []
def getKigo(url):
    response = requests.get(url)
    response.encoding = response.apparent_encoding

    tArray = []
    i = 0
    t1=response.text.split('<!--esi <esi:include src="/esitest-fa8a495983347898/content" /> -->')
    t1=t1[0].split('<div class="mw-category-group">')
    for t2 in t1:
       if i == 0:
           i+=1
           continue;
       t3=re.split('<a href=".*" title=".*">', t2)
       aText="</a></li>"
       for t4 in t3:
          if aText in t4:
             t5=t4.split("</a>")
             tArray.append(t5[0])
       i += 1
    
    crTime=re.split('.*最終更新 ', response.text)
    crTime=re.split(' （日時は<a href=',crTime[1])

    crTitle=re.split('<title>',response.text)
    crTitle=re.split(' - Wikipedia</title>',crTitle[1])
    return [tArray,crTime[0],crTitle[0]]

i = 0
kigos = {}
for key,value in urlDict.items():
   gk = getKigo(value)
   kigos[key] = gk[0]
   kigos[key+'cr'] = '「'+ gk[2] +'」『フリー百科事典　ウィキペディア日本語版』。'+ gk[1] +' UTC、URL: https://ja.wikipedia.org'

print(json.dumps(kigos,ensure_ascii=False))
