def fetch_rss_items(url, max_items = nil)
  %w{ open-uri rss/0.9 rss/1.0 rss/2.0 rss/parser }.each { |lib| require(lib) }
  rss = RSS::Parser.parse(open(url).read)
  rss.items[0...(max_items ? max_items : rss.items.length)]
end

#items = fetch_rss_items('http://www.digg.com/rss/index.xml', 5)
items = fetch_rss_items('http://weblog.easyplay.com.tw/RSS/all.xml', 5)
items.collect! { |item| item.title }
puts items
