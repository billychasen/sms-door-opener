
import urllib2


def door(request):
    '''
      This is plugged into a django env, but can really be used with anything.
      Twilio hits this URL, which pings the door and returns the response
    '''

    doorurl = 'http://url-to-parallax-server/'

    whitelist = [ "+19175551212",
                  "+19175557383",
                  ]

    fromnum = request.POST.get("From")
    body = request.POST.get("Body")

    if fromnum and body and fromnum in whitelist:
        if body == "open":
            doorurl = doorurl + '?1=o'
        elif body == "close":
            doorurl = doorurl + '?1=c'
        elif body == "status":
            pass

        try:
            doorres = urllib2.urlopen(doorurl, timeout = 10).read().strip()
        except:
            doorres = "door unresponsive"

        return HttpResponse('<Response><Sms>' + doorres + '</Sms></Response>', content_type="text/xml")

    raise Http404

