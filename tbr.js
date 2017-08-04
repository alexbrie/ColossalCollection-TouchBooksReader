/******
 Copyright 2016 Alexandru Brie. All rights reserved. 
 Contact the author at alexbrie@gmail.com for licensing inquiries.
 *******/

var Tbr  = {
    onPageLoaded : function () {
        window.webkit.messageHandlers.onPageLoaded.postMessage({});
    },
	
    getFontSize : function (){
        var fs = window.getComputedStyle(document.documentElement.getElementsByTagName("body")[0], null).getPropertyValue("font-size");
        var fontSize = parseFloat(fs);
        
        window.webkit.messageHandlers.didGetFontSize.postMessage({"size":fontSize});
    },

    setFontSize : function (tag, fs){
        var elems = document.getElementsByTagName(tag);
        for (var i = 0; i < elems.length; i++) {
            elems.item(i).style.fontSize = fs;
        }
    },

    replaceCss : function (cssCode) {
        var styleElement = document.createElement("style");
        var headID = document.getElementsByTagName('head').item(0);
        styleElement.type = "text/css";
        if (styleElement.styleSheet) {
            styleElement.styleSheet.cssText = cssCode;
        } else {
            styleElement.appendChild(document.createTextNode(cssCode));
        }
        
        for(i=0; (a = headID.getElementsByTagName("style")[i]); i++){
            a.parentNode.removeChild(a);
        }
        
        headID.appendChild(styleElement);
    },
    
    getScrollPercent : function () {
        if (document.body.scrollHeight <= document.body.scrollTop + window.innerHeight*1.05) {
            return 100.0;
        }
        else {
            return (document.body.scrollTop * 100)/document.body.scrollHeight;
        }
    },
    
    scrollToPercent : function (percent) {
        document.body.scrollTop = percent * document.body.scrollHeight / 100
        window.webkit.messageHandlers.didScroll.postMessage({"percent":percent*1.0});
    },
   
    setScrollValue : function (scroll){
        document.body.scrollTop = scroll;
    },

    scrollToElement:function (element){
        var pos = this.nodePosition(element);
        this.setScrollValue(pos);
    },
	
    /* leafs & nodes */
    
    isLeaf:function(element) {
        if (element.childNodes.length==0) return true;
        if (element.tagName.toUpperCase()=="P") return true;
        /*
        else if (element.childNodes.length==1) {
        var child = element.childNodes[0];

        if (child.childNodes.length==0) return true;
        else return false;
        }*/
        return false;
    },

    firstLeaf:function(element) {
        if (!element) return null; //ne(null)=null

        if (!this.isLeaf(element)) {
            return this.firstLeaf(element.childNodes[0]);
        }
        return element;
    },

    nextLeaf:function(element)  {
        var ns;
        if (!this.isLeaf(element)) {
            return this.firstLeaf(element.childNodes[0]);
        }

        var ns = element;
        do{
            var el = ns;
            ns = el.nextSibling;
            if (ns) return this.firstLeaf(ns);
            ns = el.parentNode;
        } 
        while(ns);
        return null;
    },
	
    /* class */

    addClass:function ( classname, element ) {
        if (element == null) {
            return;
        }
        var cn = element.className;
        //add a space if the element already has class
        if( cn != '' ) {
            classname = ' '+classname;
        }
        element.className = cn+classname;
    },
   
    removeClass:function( classname, element ) {
        if (element == null) {
            return;
        }
        var cn = element.className;
        var rxp = new RegExp( "\\s?\\b"+classname+"\\b", "g" );
        cn = cn.replace( rxp, '' );
        element.className = cn;
    },
   
    /* nodes and offsets */
    nodePosition : function(node) {
        if (!node)
            return -1;

        if (node.nodeName === '#text')
            node = node.parentNode;

        var y = node.offsetTop;
        for (var parent = node.offsetParent; parent && parent !== window; parent = parent.offsetParent)
            y += parent.offsetTop;
        return y;
    },
   
    findLeafAfterPos : function(pos){
        var leaf = Tbr.nextLeaf(document.getElementsByTagName('body')[0]);
        var i=0;
        while(leaf && Tbr.nodePosition(leaf)<pos){
            leaf = Tbr.nextLeaf(leaf);
        }
        return leaf;
    },
   
    /* get next text contents and advance current node */
   
    closestTextContents: function(currentLeaf) {
        var endOfText = false;
        do {
            if (currentLeaf == null) {
                endOfText = true;
            }
            else {
                var txt = currentLeaf.textContent.trim();
                if (txt.length > 0) {
                    return {text: txt, leaf: currentLeaf};
                }
                else {
                    currentLeaf = Tbr.nextLeaf(currentLeaf);
                }
            }
        } while (!endOfText);
        return null;
    },	
    
    readNext : function() {
        if (leafCurrent == null) {
            leafCurrent = Tbr.findLeafAfterPos(document.body.scrollTop);
        }
        else {
            leafCurrent = Tbr.nextLeaf(leafCurrent);
        }
        this.readText();
    },
    
    readText: function() {
        Tbr.removeClass("tbr_reading", leafPrevious);
        var textToRead = this.closestTextContents(leafCurrent);
        if (textToRead == null) {
            if ( typeof window.webkit != 'undefined')
            { //.messageHandlers
                window.webkit.messageHandlers.endOfTextToRead.postMessage();
            }
            else {
                console.log('end of text');
            }
        }
        else {
            //console.log(textToRead.text);
            leafCurrent = textToRead.leaf;
            Tbr.addClass("tbr_reading", leafCurrent);
            Tbr.scrollToElement(leafCurrent);
            leafPrevious = leafCurrent;

            var nextObject = this.closestTextContents(this.nextLeaf(leafCurrent));

            var nextLeaf = null;
            if (nextObject != null) {
                nextLeaf = nextObject.leaf;
            }

            var nodeHeight = nextLeaf.offsetHeight;

            var postDict = {"text":textToRead.text, "node_offset":leafCurrent.offsetTop, "node_height":nodeHeight};
            if (typeof window.webkit != 'undefined')
                { //.messageHandlers
                window.webkit.messageHandlers.newTextToRead.postMessage(postDict);
            }
            else {
                console.log(postDict);
            }
        }
    },
    
    stopReading: function() {
        Tbr.removeClass("tbr_reading", leafPrevious);
        leafCurrent = null;
        leafPrevious = null;
    }
};


var leafCurrent = null;
var leafPrevious = null;
