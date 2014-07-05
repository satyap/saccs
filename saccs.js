//<!-- js via http://developer.apple.com/internet/webcontent/xmlhttpreq.html -->
var req;
var res;
var urlbox;

function loadXMLdoc(t,results) {
    res=document.getElementById(results);
    urlbox=t;
    if((t.value.length<3) || (t.value == "http://")) {
        res.innerHTML='';
        res.style.display='none';
        return;
    }
    url='getdata.pl?val=' + escape(t.value);
    //timestamp here
    if (window.XMLHttpRequest) {
        // branch for native XMLHttpRequest object
        req = new XMLHttpRequest();
        req.onreadystatechange = processReqChange;
        req.open("GET", url, true);
        req.send(null);
    } else if (window.ActiveXObject) {
        // branch for IE/Windows ActiveX version
        req = new ActiveXObject("Microsoft.XMLHTTP");
        if (req) {
            req.onreadystatechange = processReqChange;
            req.open("GET", url, true);
            req.send();
        }
    }
}

function processReqChange() {
    // only if req shows "loaded"
    if (req.readyState == 4) {
        // only if "OK"
        if (req.status == 200) {
            //            alert(req.responseText);
            if(req.responseText == '') {
                res.innerHTML='';
                res.style.display='none';
            }
            else {
                res.innerHTML='<span class="closebutton">' +
                    '<a href="javascript:;" onclick="javascript:disappear' +
                    '(\'res\')"/>X</a></span>' + 
                    req.responseText;
                res.style.display='block';
            }
        } else {
            alert("There was a problem retrieving the XML data:\n" +
                    req.statusText);
        }
    }
}

function populate(u) {
    urlbox.value=u.innerHTML;
    res.style.display='none';
}

function disappear(u) {
    eval(u+".style.display='none'");
}
