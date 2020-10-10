require 'discordrb' #gem installする
require 'date'
require 'json'
require 'net/http'
require 'uri'
require 'timers'    #gem installする
require 'open-uri'  #gem installする
require 'nokogiri'  #gem installする

##### このbotのフォルダ構造 #####
# 以下の通りである必要がある
# discordbot.rb : このbotのプログラム
# CLIENT.aykbot : Client IDを記述する
# TOKEN.aykbot  : Tokenを記述する
# - kazuate        : kazuateコマンドに使用するフォルダ
# - memo           : memoコマンドに使用するフォルダ

##### このbotが持つ機能 #####
# - 以下のコマンド実行

##### コマンドリスト#####

# botシステム系
# - timercheck
# - > タイマーが実行中か確認する
# - timerstop
# - > タイマーの実行を止める
# - heartbeatcount
# - > Heartbeatの回数を返す

# チャット系
# - ping
# - > pongを返す
# - hello
# - > Hello, Worldを返す
# - help
# - > helpを返す
# - gif 名前
# - > 指定した名前のgifに変換する
# - asbot テキスト
# - > テキストの内容をbotに発言させる
# - list 内容
# - > リストを表示する
# - > helpコマンドのようなもの

# ボイスチャット系
# - join
# - > ボイスチャットに入る
# - leave
# - > ボイスチャットから抜ける

# ツール系
# - dice
# - > 1~6の乱数を返す
# - dicex 最小値 最大値 回数
# - > 指定範囲の乱数を返す
# - dicet 回数 最大値
# - > 最大値までの乱数を返す
# - calc 数値A 演算子 数値B
# - > 数値Aと数値Bを指定演算子で計算する
# - > 演算子：+ - * / %
# - omikuji
# - > おみくじを引く
# - causeme オプション
# - > あやかちゃんbotが罵ってくれる
# - > オプション
# - - > about：このコマンドについて返す
# - - > heart：文末に♡をつける
# - memo 名前 モード テキスト
# - > メモ機能
# - > 名前：メモの名前
# - > モード
# - - > read ：指定した名前のメモを返す
# - - > write：指定した名前でメモを書き込む
# - > テキスト：メモの内容
# - timer 時間 名前
# - > タイマー機能
# - > 時間は秒単位で指定する
# - > 名前をつけることができる
# - > 同時に使えるタイマーは1つまで
# - earthquake
# - > 地震情報を取得する
# - typhoon
# - > 台風情報を取得する

# ゲーム系
# - janken 手
# - > じゃんけんをする
# - > 手：ぐー ちょき ぱー (カタカナ可)
# - kazuate 数字
# - > 数当てゲーム
# - > 数字：1~100の範囲
# - > 数字にregenを指定すると新しく生成する

# The Hiveプレイヤー向けコマンド
# - hiveplayer プレイヤー名 ゲーム名
# - > 指定したプレイヤーのステータスを返す
# - > ゲーム名は省略可能
# - > ゲーム名：dr grav hide timv bp draw sp
# - hiveplayercount
# - > The Hiveに接続している人数を返す
# - calcblockexp レベル
# - > 指定レベルまでに必要な経験値を返す

File.open("TOKEN.aykbot", "r") do |rtext|
  $bottoken = rtext.read
end

File.open("CLIENT.aykbot", "r") do |rtext|
  $botclient = rtext.read.to_i
end

timers = Timers::Group.new

#puts "Token: #{$bottoken}"
#puts "Client ID: #{$botclient}"

bot = Discordrb::Commands::CommandBot.new token: $bottoken,  client_id: $botclient, prefix: "-"

BOTVERSION = "Ayaka-bot 1.10"
BOTPLAYING = "-help でヘルプ"
TIMERMAX = 1
nowdate = Date.today
nowtime = DateTime.now

$playing = [
  '-help でヘルプ',
  'あやかちゃんは魔法少女',
  '16才だよ',
  'ニンゲンです',
  'ねむたい',
  '女の子が空から降ってこないかな',
  '実装してほしいもの募集中',
  'お友達がほしい',
  'お金ください',
  ''
]

$gaming_colors = ['FF0000', 'FF8000', 'FFFF00', '80FF00', '00FF00', '00FF80', '00FFFF',
'0080FF', '0000FF', '8000FF', 'FF00FF', 'FF0080' ]

$gaming_count = 0
$timer_count = 0
$timer_isstop = 0
$heartbeat_count = 0
$vc_join_channel = nil
$vc_join_channelname = ""

bot.ready do |event|
  bot.game = BOTPLAYING
  puts "[BOT READY] (#{nowtime}}) OK"
end

bot.message do |event|
  nowdate = Date.today
  nowtime = DateTime.now
  puts "[RECEIVED] (#{event.timestamp + (9*60*60)}) <#{event.user.name}> #{event.message.content} @ #{event.channel.name} on #{event.server.name}"
end

bot.heartbeat do |event|
  #puts "[HEARTBEAT] (#{nowtime})"
  #puts "Gaming Color: #{$gaming_colors[$gaming_count]} (#{$gaming_count})"
  $heartbeat_count = $heartbeat_count + 1
  #$gaming_count = $gaming_count + 1
  #if $gaming_count >= $gaming_colors.size
  #  $gaming_count = 0
  #end
  bot.game = $playing[rand(0..$playing.size-1)]
end

# help
bot.command :help do |event|
    event.respond "```DIFF
[ヘルプ このbotについて]
-> bot開発者
     あやかちゃん (魔法少女)
-> botバージョン
     #{BOTVERSION}
-> 開発言語
     Ruby

-> - が接頭辞なので、コマンドの前に - をつけてください```
"
  event.channel.send_embed do |embed|
    embed.title = "コマンド一覧はこちら"
    embed.url = "http://ayacia.starfree.jp/botcommands.html"
  end
end

# ping
bot.command :ping do |event|
  responce = event.respond "pong! #{event.user.name}さん！"
  responce.edit "pong! #{event.user.name}さん！ (応答時間 #{Time.now - event.timestamp}秒)"
end

# hello
bot.command :hello do |event|
  event.respond "Hello, World"
end

# dice
bot.command :dice do |event|
  event.respond "サイコロを振ります！"
  sleep(0.5)
  event.respond "コロコロコロ..."
  sleep(0.5)
  event.respond "#{rand(1..6)}"
end

# dicex
bot.command :dicex do |event, dmin, dmax, dloop|
  dmin = dmin.to_i
  dmax = dmax.to_i
  dloop = dloop.to_i
  results = []
  if dmin < 0
    dmin = 0
  end
  if dmax < dmin
    dmax = dmin
  end
  if dloop < 1
    dloop = 1
  end
  for i in 1..dloop
  results.push(rand(dmin..dmax))
  end
  event.respond "さいころを振ります！ (#{dmin}～#{dmax} #{dloop}回)"
  sleep(0.5)
  event.respond "コロコロコロ..."
  sleep(0.5)
  results.unshift("合計 #{results.inject(:+)}", "(")
  results.push(")")
  results.join(" ")
end

# dicet
bot.command :dicet do |event, dloop, dmax|
  dloop = dloop.to_i
  dmax = dmax.to_i
  results = []
  if dmax < 1
    dmax = 1
  end
  if dloop < 1
    dloop = 1
  end
  for i in 1..dloop
    results.push(rand(1..dmax))
  end
  event.respond "さいころを振ります！ (#{dloop}d#{dmax})"
  sleep(0.5)
  event.respond "コロコロコロ..."
  sleep(0.5)
  results.unshift("合計 #{results.inject(:+)}", "(")
  results.push(")")
  results.join(" ")
end

# calc
bot.command :calc do |event, num_a, symb, num_b|
  num_a = num_a.to_f
  num_b = num_b.to_f
  ans = 0.to_f
  f = 0 # 0:通常 1:0で除算 2:
  if symb == "+"
    ans = num_a + num_b
  elsif symb == "-"
    ans = num_a - num_b
  elsif symb == "*"
    ans = num_a * num_b
  elsif symb == "/"
    if num_b != 0
      ans = num_a / num_b
    else
      f = 1
    end
  elsif symb == "%"
    if num_b != 0
      ans = num_a % num_b
    else
      f = 1
    end
  else
    f = 2
  end
  case f
    when 0 then
      event.respond "#{num_a} #{symb} #{num_b} = #{ans} です！"
    when 1 then
      event.respond "0で割ることはできません..."
    when 2 then
      event.respond "その計算はできません..."
  end
end

# omikuji
bot.command :omikuji do |event|
  omikuji = ["大吉", "吉", "中吉", "小吉", "末吉", "凶", "大凶"]
  event.respond "おみくじを引きます！"
  sleep(0.5)
  event.respond "カラカラカラ..."
  sleep(0.5)
  event.respond "#{omikuji[rand(0..6)]} です！"
end

# janken
bot.command :janken do |event, hand|
  # 0:グー 1:チョキ 2:パー
  if hand == "ぐー" or hand == "グー"
    handm = 0
  elsif hand == "ちょき" or hand == "チョキ"
    handm = 1
  elsif hand == "ぱー" or hand == "パー"
    handm = 2
  end
  hande = rand(0..2)
  case handm
  when 0 then
    case hande
    when 0 then #グー　 グー　　あいこ
      event.respond "グー！"
      sleep(0.5)
      event.respond "あいこです！"
    when 1 then #グー　 チョキ　かち
      event.respond "チョキ！"
      sleep(0.5)
      event.respond "あなたのかちです！"
    when 2 then #グー　 パー　　まけ
      event.respond "パー！"
      sleep(0.5)
      event.respond "わたしのかちです！"
    end
  when 1 then
    case hande
    when 0 then #チョキ グー　　まけ
      event.respond "グー！"
      sleep(0.5)
      event.respond "わたしのかちです！"
    when 1 then #チョキ チョキ　あいこ
      event.respond "チョキ！"
      sleep(0.5)
      event.respond "あいこです！"
    when 2 then #チョキ パー　　かち
      event.respond "パー！"
      sleep(0.5)
      event.respond "あなたのかちです！"
    end
  when 2 then
    case hande
    when 0 then #パー　 グー　　かち
      event.respond "グー！"
      sleep(0.5)
      event.respond "あなたのかちです！"
    when 1 then #パー　 チョキ　まけ
      event.respond "チョキ！"
      sleep(0.5)
      event.respond "わたしのかちです！"
    when 2 then #パー 　パー　　あいこ
      event.respond "パー！"
      sleep(0.5)
      event.respond "あいこです！"
    end
  end
end

# hiveplayer
bot.command :hiveplayer do |event, playername, gamename|
  case gamename
  when "dr" then
    url = 'https://api.hivemc.com/v1/player/' + playername + '/' + gamename + ''
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername} in #{gamename.upcase}]
-> Total Points
   #{hash["total_points"]}
-> Rank
   #{hash["title"]}
-> Games Played
   #{hash["games_played"]}
-> Victories
   #{hash["victories"]}
-> Deaths
   #{hash["deaths"]}
-> Kills
   #{hash["kills"]}```"
  when "grav" then
    url = 'https://api.hivemc.com/v1/player/' + playername + '/' + gamename + ''
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername} in #{gamename.upcase}]
-> Points
   #{hash["points"]}
-> Rank
   #{hash["title"]}
-> Games Played
   #{hash["gamesplayed"]}
-> Victories
   #{hash["victories"]}```
"
  when "hide" then
    url = 'https://api.hivemc.com/v1/player/' + playername + '/' + gamename + ''
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername} in #{gamename.upcase}]
-> Points
   #{hash["total_points"]}
-> Rank
   #{hash["title"]}
-> Games Played
   #{hash["gamesplayed"]}
-> Victories
   #{hash["victories"]}
-> Deaths
   #{hash["deaths"]}
-> Kills as Seeker
   #{hash["seekerkills"]}
-> Kills as Hider
   #{hash["hiderkills"]}
-> Time Alive
   #{hash["timealive"]}```"
  when "timv" then
    url = 'https://api.hivemc.com/v1/player/' + playername + '/' + gamename + ''
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername} in #{gamename.upcase}]
-> Points
   #{hash["total_points"]}
-> Rank
   #{hash["title"]}
-> Most Points
   #{hash["most_points"]}
-> Role Points
   #{hash["role_points"]}
-> Traitor Points
   #{hash["t_points"]}
-> Innocent Points
   #{hash["i_points"]}
-> Detective Points
   #{hash["d_points"]}```"
  when "bp" then
    url = 'https://api.hivemc.com/v1/player/' + playername + '/' + gamename + ''
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername} in #{gamename.upcase}]
-> Points
   #{hash["total_points"]}
-> Rank
   #{hash["title"]}
-> Games Played
   #{hash["games_played"]}
-> Total Top 3's
   #{hash["total_placing"]}
-> Eliminations
   #{hash["total_eliminations"]}```"
  when "draw" then
    url = 'https://api.hivemc.com/v1/player/' + playername + '/' + gamename + ''
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername} in #{gamename.upcase}]
-> Points
   #{hash["total_points"]}
-> Rank
   #{hash["title"]}
-> Games Played
   #{hash["gamesplayed"]}
-> Victories
   #{hash["victories"]}
-> Correct Guesses
   #{hash["correct_guesses"]}
-> Incorrect Guesses
   #{hash["incorrect_guesses"]}
-> Skips
   #{hash["skips"]}```"
  when "sp" then
    url = 'https://api.hivemc.com/v1/player/' + playername + '/' + gamename + ''
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername} in #{gamename.upcase}]
-> Points
   #{hash["points"]}
-> Rank
   #{hash["title"]}
-> Games Played
   #{hash["gamesplayed"]}
-> Victories
   #{hash["victories"]}
-> Deaths
   #{hash["deaths"]}
-> Eggs Fired
   #{hash["eggfired"]}
-> Blocks Destroyed
   #{hash["blocksdestroyed"]}
-> Time Alive
   #{hash["timealive"]}```"
  else
    url = 'https://api.hivemc.com/v1/player/' + playername
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    hash = JSON.parse(response.body)
    event.respond "```DIFF
[Player → #{playername}]
-> Player Name
   #{hash["username"]}
-> Tokens
   #{hash["tokens"]}
-> Medals
   #{hash["medals"]}
-> Crates
   #{hash["crates"]}```"
  end
end

# hiveplayercount
bot.command :hiveplayercount do |event|
  url = 'https://api.hivemc.com/v1/server/playercount'
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  hash = JSON.parse(response.body)
  puts "Players Count: #{hash["count"]}"
  event.respond "```DIFF
[Players Count]
-> Players Count
   #{hash["count"]}```"
end

# curseme
bot.command :curseme do |event, option|
  if option == "about"
    event.respond "```DIFF
[cursemeコマンドについて]
-> コマンドの発案者
     凸守
-> 協力者
     凸守

-> セリフ思いついたら投げつけてくれると追加すると思います```"
  else
    cursemessage = [
      "ばーか",
      "くず",
      "ざーこ",
      "ざこポンチ",
      "負けちゃえ",
      "なさけなーい",
      "よわよわポンチ"
    ]
    curseselect = rand(0..cursemessage.size)
    cursetext = cursemessage[curseselect]
    if option == "heart"
      cursetext = cursetext + "♡"
    end
    event.respond cursetext
  end
end

# memo
bot.command :memo do |event, name, mode, text|
  if name != ""
    if mode == "read"
      File.open("memo/"+name+".txt", "r") do |rtext|
        event.respond "```
[メモ 読み込み #{name}.txt]
#{rtext.read}```"
      end
    elsif mode == "write"
      File.open("memo/"+name+".txt", "w") do |wtext|
        wtext.puts(text)
        event.respond "```
[メモ 書き込み #{name}.txt]
#{text}```"
      end
    end
  end
end

# kazuate
bot.command :kazuate do |event, num|
  if num == "regen"
    correct = rand(0..99)
    File.open("kazuate/correct.txt", "w") do |wtext|
      wtext.puts(correct.to_s)
    end
      event.respond "新しく数字を生成しました！"
      puts "Correct Number: #{correct}"
    else
      File.open("kazuate/correct.txt", "r") do |rtext|
        correct = rtext.read
      end
        correct = correct.to_i
        num = num.to_i
        if num < correct
          event.respond "もっと大きいよ！"
        elsif num > correct
          event.respond "もっと小さいよ！"
        else
          event.respond "正解です！おめでとう！"
          sleep(0.5)
          File.open("kazuate/correct.txt", "w") do |wtext|
            correct = rand(0..99)
            wtext.puts(correct.to_s)
          end
          event.respond "新しく数字を生成しました！"
          puts "Correct Number: #{correct}"
    end
  end
end

# timer
bot.command :timer do |event, seconds, title|
  seconds = seconds.to_i
  counter = 0
  if $timer_count < TIMERMAX
    $timer_count = $timer_count + 1
    if title != nil
      title = "[" + title + "]"
    else
      title = ""
    end
    responce = event.respond "```タイマー #{title}\n残り時間 #{seconds - counter}秒```"
    loop{
      responce.edit "```タイマー #{title}\n残り時間 #{seconds - counter}秒```"
      if seconds == counter
        break
      end
      if $timer_isstop == 1
        break
      end
      counter = counter + 1
      sleep(1)
    }
    $timer_count = $timer_count - 1
    if $timer_isstop == 0
      responce.edit "```タイマー #{title}\n時間になりました (#{seconds}秒)"
    else
      responce.edit "```タイマー #{title}\n中断しました```"
      $timer_isstop = 0
    end
  else
    event.respond "#{TIMERMAX + 1}つ以上同時にタイマーを実行することはできません！"
  end
end

# timerstop
bot.command :timerstop do |event|
  $timer_isstop = 1
  event.respond "タイマーを中断しました！"
end

# timercheck
bot.command :timercheck do |event|
  if $timer_count == 0
    event.respond "タイマーは実行していません"
  else
    event.respond "タイマーは実行中です"
  end
end

# earthquake
bot.command :earthquake do |event|
  url = "https://typhoon.yahoo.co.jp/weather/jp/earthquake/"
  charset = nil
  html = open(url) do |webpage|
    charset = webpage.charset
    webpage.read
  end
  contents = Nokogiri::HTML.parse(html, nil, charset)
  eqtable = contents.xpath("//td")
  eqimg = contents.xpath("//img")
  #震度分布画像
  eqimgurl = eqimg[4].to_s
  eqimgurl = eqimgurl.slice(10..eqimgurl.length-16)
  #発生時刻
  eqtime = eqtable[2].text
  #震源地
  eqplace = eqtable[4].text
  #最大震度
  eqmax = eqtable[6].text
  #マグニチュード
  eqmag = eqtable[8].text
  #深さ
  eqdepth = eqtable[10].text
  #津波情報
  eqtsunami = eqtable[14].text
  event.send_embed do |embed|
    embed.title = eqplace
    embed.url = url
    embed.description = eqtime
    embed.add_field(
      name: "最大震度",
      value: eqmax,
      inline: true
    )
    embed.add_field(
      name: "マグニチュード",
      value: eqmag,
      inline: true
    )
    embed.add_field(
      name: "深さ",
      value: eqdepth,
      inline: true
    )
    embed.add_field(
      name: "津波情報",
      value: eqtsunami,
      inline: false
    )
    embed.image = Discordrb::Webhooks::EmbedImage.new(url: eqimgurl)
  end
end

# typhoon
bot.command :typhoon do |event|
  url = "https://typhoon.yahoo.co.jp/weather/jp/typhoon/?c=1"
  charset = nil
  html = open(url) do |webpage|
    charset = webpage.charset
    webpage.read
  end
  contents = Nokogiri::HTML.parse(html, nil, charset)
  tptable = contents.xpath("//dd")
  tpimg = contents.xpath("//img")
  tph3 = contents.xpath("//h3")
  #台風番号
  tpnumber = tph3[0].to_s
  tpnumber = tpnumber.slice(4..tpnumber.length-6)
  if tpnumber.slice(2..3).to_i > 0
    #現在位置画像
    tpimgurl = tpimg[4].to_s
    tpimgurl = tpimgurl.slice(10..tpimgurl.length-27)
    #名称
    tpname = tptable[0].text
    #大きさ
    tpsize = tptable[1].text
    #強さ
    tpstrong = tptable[2].text
    #現在位置
    tpplace = tptable[3].text
    #進行方向・速さ
    tpdir = tptable[5].text
    tpspeed = tptable[6].text
    #中心気圧
    tpatom = tptable[7].text
    #最大風速・最大瞬間風速
    tpwind = tptable[8].text
    tpswind = tptable[9].text
    event.send_embed do |embed|
      embed.title = tpnumber
      embed.description = tpname
      embed.url = url
      embed.add_field(
        name: "現在位置",
        value: tpplace,
        inline: true
      )
      embed.add_field(
        name: "大きさ",
        value: tpsize,
        inline: true
      )
      embed.add_field(
        name: "強さ",
        value: tpstrong,
        inline: true
      )
      embed.add_field(
        name: "進行方向・速度",
        value: "#{tpdir} #{tpspeed}",
        inline: true
      )
      embed.add_field(
        name: "中心気圧",
        value: tpatom,
        inline: true
      )
      embed.add_field(
        name: "最大風速 (瞬間風速)",
        value: "#{tpwind} (#{tpswind})",
        inline: true
      )
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: tpimgurl)
    end
  else
    event.send_embed do |embed|
      embed.title = "現在台風情報は発表されていません"
    end
  end
end

# gif
bot.command :gif do |event, name|
  event.message.delete
  case name
  when "gsbl" then #GET STICK BUGGED LOL
    event.respond "https://tenor.com/view/get-stick-bugged-lol-gif-18048663"
  when "lulu" then #LULU SUZUHARA MITANA...
    event.respond "https://tenor.com/view/suzuhara-suzuhara-lulu-vtuber-blush-cute-gif-17751938"
  when "umaru" then #CRYING UMARU
    event.respond "https://tenor.com/view/sad-worst-gif-18746964"
  when "vignette" then #VIGNETTE SURPRISED
    event.respond "https://tenor.com/view/gabriel-dropout-vignette-gif-18640619" 
  end
end

# asbot
bot.command :asbot do |event, text|
  event.message.delete
  event.respond text
end

# list
bot.command :list do |event, text|
  case text
  when "markdown" then
    event.respond "** → 太字\n_ → 斜体\n* → 斜体\n__ → 下線\n~~ → 打ち消し線\n|| → ネタバレ\n\` → インラインコードブロック\n\`\`\` → コードブロック"
  end
end

# calcblockexp
bot.command :calcblockexp do |event, lvl|
  event.respond "レベル#{lvl.to_i} までに #{25*(lvl.to_i)*(lvl.to_i-1)} 経験値が必要です！"
end

# heartbeatcount
bot.command :heartbeatcount do |event|
  event.respond "#{$heartbeat_count}回Heartbeatしました！"
end

# join
bot.command :join do |event|
  channel = event.user.voice_channel
  next "ボイスチャンネルに入っている必要があります！" unless channel
  $vc_join_channel = channel
  $vc_join_channelname = channel.name
  bot.voice_connect(channel)
  event.respond "ボイスチャンネル(#{channel.name})に入りました！"

end

# leave
bot.command :leave do |event|
  puts $vc_join_channel
  puts $vc_join_channelname
  next "ボイスチャンネルに入っていません" unless $vc_join_channel
  event.respond "ボイスチャンネル(#{$vc_join_channelname})から抜けました！"
  $vc_join_channel = nil
  $vc_join_channelname = ""
  bot.voice_destroy(event.server)
end





bot.command :test do |event, a|
  puts a
end

# Botの実行
bot.run