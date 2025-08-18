import sys

config.load_autoconfig()

if sys.platform.startswith("win"):
    config.set("editor.command", ["wt.exe", "nvim", "-f", "{file}", "-c", "normal {line}G{column0}l"])
    config.bind(f"{leader}swi", "spawn -o pwsh.exe -c Start-WorkOnAdoItem.ps1 -WorkItemUrl {url}")
    config.bind(f"{leader}oe", "spawn pwsh.exe -c Start-Process \"{url}\"")

default_zoom = "80%"
leader = "<Space>"

config.set("colors.webpage.darkmode.enabled", True, "*")
config.set("colors.webpage.darkmode.enabled", False, "*://dev.azure.com/*")
config.set("colors.webpage.darkmode.enabled", False, "*://ai-chat.msyke.dev/*")

config.set("content.user_stylesheets", ["./stylesheets/toggl-settings.css"])

config.set("zoom.default", default_zoom)
config.set("zoom.levels", ["25%", "33%", "50%", "75%", "80%", "90%", "100%", "110%", "120%", "130%", "140%", "150%"])

config.bind("x", "tab-close")

config.bind(f"{leader}zd", f"set zoom.default {default_zoom}")
config.bind(f"{leader}zi", f"set zoom.default 110%")
config.bind(f"{leader}su", "quickmark-load -t sprint ;; zoom 110%")
config.bind(f"{leader}eu", "cmd-set-text -s :open {url:pretty}")
config.bind(f"{leader}dtb", "devtools bottom")
config.bind(f"{leader}dtr", "devtools right")
config.bind(f"{leader}dtc", "devtools")

config.set("url.start_pages", "https://www.google.com")

c.url.searchengines = {
    'DEFAULT':  'https://google.com/search?hl=en&q={}',
    '!a':       'https://www.amazon.com/s?k={}',
    '!d':       'https://duckduckgo.com/?ia=web&q={}',
    '!dd':      'https://thefreedictionary.com/{}',
    '!e':       'https://www.ebay.com/sch/i.html?_nkw={}',
    '!fb':      'https://www.facebook.com/s.php?q={}',
    '!gh':      'https://github.com/search?o=desc&q={}&s=stars',
    '!gist':    'https://gist.github.com/search?q={}',
    '!gi':      'https://www.google.com/search?tbm=isch&q={}&tbs=imgo:1',
    '!gn':      'https://news.google.com/search?q={}',
    '!ig':      'https://www.instagram.com/explore/tags/{}',
    '!m':       'https://www.google.com/maps/search/{}',
    '!p':       'https://pry.sh/{}',
    '!r':       'https://www.reddit.com/search?q={}',
    '!sd':      'https://slickdeals.net/newsearch.php?q={}&searcharea=deals&searchin=first',
    '!t':       'https://www.thesaurus.com/browse/{}',
    '!tw':      'https://twitter.com/search?q={}',
    '!w':       'https://en.wikipedia.org/wiki/{}',
    '!yelp':    'https://www.yelp.com/search?find_desc={}',
    '!yt':      'https://www.youtube.com/results?search_query={}'
}

