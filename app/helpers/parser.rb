require 'nokogiri'
require 'open-uri'
require 'rest-client'
# 
# 올림픽에는 7개의 경기, 15개의 종목, 102개의 세부 종목괄호 안의 숫자는 금메달 수이다.
# Alpine skiing 알파인 스키 (11)
# Biathlon 바이애슬론 (11)
# Bobsleigh  봅슬레이 (3)
# Cross country  크로스컨트리 (12)
# Curling  컬링 (3)
# Figure skating  피겨스케이팅 (5)
# Freestyle skiing  프리스타일 스키 (10)
# Ice hockey  아이스하키 (2)
# Luge  루지 (4)
# Nordic combined  노르딕 복합 (3)
# Short track speed skating  쇼트트랙 (8)
# Skeleton  스켈레톤 (2)
# Ski jumping  스키점프 (4)
# Snowboarding  스노보드 (10)
# Speed skating  스피드스케이팅 (14)
module Parser
    class Game
        # 경기일정 출력하는것
        def Info(mday, menu)
            # require 'open-uri'
            # require 'nokogiri'
            require 'awesome_print'
            require "json"
            
            # mday = "10"
            url = "http://m.sports.news.naver.com/pc2018/schedule/index.nhn?type=date&onlyKorea=false&date=201802#{mday}"
            
            doc = Nokogiri::XML(open(url),nil,'utf-8')
            raw_data = doc.css('body').to_s
            
            data = raw_data.scan(/e\({(?>[^$])*[^\']}\);+/)
            data = data[0].scan(/{(?>[^$])*[^\']}+/)
            
            data = data[0].to_s.gsub("\n","")
            data = data.gsub("<br>", " ")
            
            parsed = JSON.parse(data) # All Schedule Data

            mes = textmake(parsed, menu)
            # ap mes
            return mes
            # return "<" + a + ">"
        end
            
        def Rank
            url = "https://www.pyeongchang2018.com/ko/game-time/results/OWG2018/ko/general/medal-standings.htm"
            doc = Nokogiri::HTML(open(url))
            res = Array.new
            @posts = doc.css('#mainBodyContent-left')
            # p @posts
            result = ""
            json = ""
            @posts.each do |pw|
                data = pw.text
                data = data.to_s.gsub("\n","")
                data = data.to_s.gsub("\t","")
                result = data
                json = data
            end
            # p json
            # 긁어서 이상한 부분 날리는 코드
            # p result
            medal_final = Array.new
            result = result[157..result.length-211].split

            for i in 0..result.length
                if result[i] == "러시아"
                result[i] = "러시아 출신 올림픽 선수"
                result[i+1]= result[i+4]
                result[i+2]= result[i+5]
                result.delete_at(i+5)
                result[i+3]= result[i+5]
                result.delete_at(i+5)
                result[i+4]= result[i+5]
                result.delete_at(i+5)
                end
            end
            # 러시아 출신 올림픽 선수 처리하는 알고리즘 3칸씩 당긴다 ( result 주석해제하고 확인)
            medal_final = Array.new
            for i in 1..result.length
                list = ""
                if i%6==0
                medal_final << result[i-6..i-1].join(" ")
                elsif i%6==2 or i%6==3 or i%6==4
                country = result[i] + " /"
                result[i] = country
                end
            end
            medal_final.unshift("순위 나라 금 은 동 전체")
            msg = medal_final[0..10].join("\n")

            return msg
        end

        
        def data_parser(data)
    
            res = Hash.new
        
            res["entry"] = data["disciplineName"]
            res["title"] = data["title"]
            time = data["localDateTimeOfDateTime"]
            res["hh"] = "%02d" % time["hour"]
            res["mm"] = "%02d" % time["minute"]
            res["gamestatus"] = data["statusCode"]
            
            if data["eventCode"] == "CL" || data["eventCode"] == "OP"
                return res
            end
            
            if data["gameType"] == "record"
                pla = Array.new
                
                data["result"]["record"].each do |result|
                    pl = Hash.new
                    pl["isteam"] = data["isTeam"]
                    pl["p_name"] = data["isTeam"] == "N" ? result["playerName"] : data["koreanPlayerListText"]
                    pl["p_ctry"] = result["countryName"]
                    
                    pl["qmark"] = result["result"]["qmark"]
                    pl["medal"] = result["result"]["medal"]
                    pl["rank"] = result["result"]["ranking"]
                    pl["newrecord"] = result["result"]["newrecord"]
                    pl["record"] = result["result"]["stats"]
        
                    pla << pl
                end
                res["playerlist"] = pla
            elsif data["gameType"] == "match"
                result = data["result"]["match"]
        
                res["t_name"] = data["koreanPlayerListText"]
                res["home"] = result["homeName"]
                res["away"] = result["awayName"]
                res["homescr"] = result["homeScore"]
                res["awayscr"] = result["awayScore"]
        
                res["h_rank"] = result["homeResult"]["ranking"]
                res["h_medal"] = result["homeResult"]["medal"]
                res["h_qmark"] = result["homeResult"]["qmark"]
                res["a_rank"] = result["awayResult"]["ranking"]
                res["a_medal"] = result["awayResult"]["medal"]
                res["a_qmark"] = result["homeResult"]["qmark"]
            end
            
            return res
        end
        
        def yesterday_did(res, md, type="record")
            ##################################################
                    #어제 경기
            #-------------------------------------------------
            #  <루지> - 여자 예선
            #  ○ 박보검(금) WR
            
            #  <컬링> - 단체전 예선
            #  ○ 대한민국 3:5 캐나다
            
            #  <스피드스케이팅> - 여자 1500m 결승
            #  ○ 황진이/대한민국 (7위)
            #
            # Message Format (qmark: 기권 유무)
            # << 어제 경기 결과 >>
            #  <entry> - title
            #  ○ name/country (medal or rank or qmark) newrecord   
            #-------------------------------------------------   
            cont = Array.new
            cont << "<#{res["entry"]}> -#{res["title"]}"
            
            if (type == "match")
                    hm = (res["h_medal"] != "") ? "#{md[res["h_medal"]]}" : "#{res["h_rank"]} #{res["h_qmark"]}"
                    am = (res["a_medal"] != "") ? "#{md[res["a_medal"]]}" : "#{res["a_rank"]} #{res["a_qmark"]}"
                    h_me = (hm == "" || hm == " ") ? "" : "(#{hm})"
                    a_me = (am == "" || am == " ") ? "" : "(#{am})"
                    
                    t = "○ #{res["home"]}#{h_me} #{res["homescr"]} : #{res["awayscr"]} #{res["away"]}#{a_me}"
                    cont << t
            else
                res["playerlist"].each do |pl|
                    if pl["p_ctry"] == "대한민국"
                        qmark = (pl["qmark"] == "") ? "" : "-#{pl["qmark"]}"
                        rank = (pl["rank"] == "") ? "#{pl["qmark"]}" : "#{pl["rank"]}위#{qmark}"
                        p_info = (pl["p_name"] == "") ? "#{pl["p_ctry"]}" : "#{pl["p_name"]}/#{pl["p_ctry"]}"
                        
                        t = (pl["medal"] != "") ? "○ #{p_info} (#{md[pl["medal"]]}) #{pl["newrecord"]}" : "○ #{p_info} (#{rank})"
                        cont << t
                    end
                end
            end
            
            cont << " "
            return cont
        end
        
        def today_schedule(res, gamestatus, type="record")
            ##################################################
                    #오늘 전체 일정
            #-------------------------------------------------        
            #   ■■■[경기종료]■■■
            #   <봅습레이> - 2인썰매
            #   ○ 시간 : 13:00
            #   (11위) 대한민국
            #   
            #   ■■■[진행중]■■■
            #   <스키점프> - 남자 루프탑
            #   ○ 시간 : 13:20
            
            #   ■■■[경기전]■■■  
            #   <쇼트트렉> - 여자 500m 결승
            #   ○ 시간 : 14:10
            #
            # Message Format
            #   ■■■[status]■■■
            #   <entry> - title
            #   ○ 시간 : time
            #-------------------------------------------------
            cont = Array.new
            gst, shp = gamestatus[res["gamestatus"]]
            cont << "#{shp*4} [#{gst}] #{shp*4}"
            cont << "<#{res["entry"]}> -#{res["title"]}"
            
            if gst == "경기종료"
                if type == "record"
                    res["playerlist"].each do |pl|
                        p_info = (pl["isteam"] == "N") ? "#{pl["p_name"]}/#{pl["p_ctry"]}" : "#{pl["p_ctry"]}"
                    
                        qmark = (pl["qmark"] == "") ? "" : "-#{pl["qmark"]}"
                        rank_info = (pl["rank"] == "") ? "#{pl["qmark"]}" : "#{pl["rank"]}위#{qmark}"

                        g_res = (pl["medal"] != "") ? " (#{md[pl["medal"]]})#{p_info}" : " (#{rank_info})#{p_info}"

                        cont << g_res
                    end
                else
                    cont << "#{res["home"]} #{res["homescr"]} : #{res["awayscr"]} #{res["away"]}"
                end
            else
                cont << "○ 시간 : #{res["hh"]}:#{res["mm"]}"
                # cont << "○ 시간 : #{res["hh"]}:#{res["mm"]} (#{gamestatus[res["gamestatus"]]})"
            end
            
            cont << " "
            
            return cont
        end
        
        def today_entry(res, md, gamestatus, type="record")
            ##################################################        
            #   빙판 / 설원 / 썰매
            #-------------------------------------------------
            #   ■■■[경기종료]■■■
            #   <쇼트트렉> - 남자 500m 
            #   ○ 시간 : 14:10
            #   ○ 참가선수
            #    (금) 박보검/대한민국 - 1:43.28 OR
            
            #   ■■■[경기전]■■■
            #   <아이스 하키> - 남자
            #   ○ 시간 : 14:30
            #   ○ 대한민국(금) 5 : 3 캐나다(동)
            #   ○ 참가선수
            #    - 박보검 홍길동 장동건 박문수
            
            #   ■■■[경기전]■■■
            #   <스키점프> - 남자 다운힐
            #   ○ 시간 : 13:20 
            #   ○ 박보검/대한민국
            
            #   ■■■[경기종료]■■■
            #   <봅슬레이> - 남자 2인승
            #   ○ 시간 : 13:00
            #   (금) 네덜란드 - 1:02.11 OR
            #   (은) 스웨덴 - 1:02.55
            #   (동) 노르웨이 - 1:02.85
            #   (7위) 대한민국 - 1:03.44
            #
            # Message Format
            # entry - title
            # 시간 : time status
            #
            # !개인전인 경우
            # 참가 선수
            #  !종료전 : playerName / country
            #  !종료시 : (medal or rank or qmark) playerName - stats newrecord
            #
            # !팀인 경우
            # 결과 (종료시)
            #  레코드 및 점수 경기시
            #  (medal or rank or qmark) countryName - stats newrecord
            #  매칭 경기시
            #  homename(medal)  score : score awayname (medal)
            # 참가선수
            #  playerList
            ##################################################
            cont = Array.new
            gst, shp = gamestatus[res["gamestatus"]]
            cont << "#{shp*4} [#{gst}] #{shp*4}"
            cont << "<#{res["entry"]}> -#{res["title"]}"
            cont << "○ 시간 : #{res["hh"]}:#{res["mm"]}" 
            
            
            if type == "record"
                cont << "○ 참가선수"
                res["playerlist"].each do |pl|
                    p_info = (pl["isteam"] == "N") ? "#{pl["p_name"]}/#{pl["p_ctry"]}" : "#{pl["p_ctry"]}"
                    
                    if (res["gamestatus"] == "RESULT")
                        qmark = (pl["qmark"] == "") ? "" : "-#{pl["qmark"]}"
                        rank_info = (pl["rank"] == "") ? "#{pl["qmark"]}" : "#{pl["rank"]}위#{qmark}"
                        rec_info = "#{pl["record"]} #{pl["newrecord"]}"
                        
                        g_res = (pl["medal"] != "") ? " (#{md[pl["medal"]]})#{p_info} #{rec_info}" : " (#{rank_info})#{p_info} #{rec_info}"
                    else
                        g_res = " - #{p_info}"                                
                    end
                    
                    cont << g_res
                    if pl["isteam"] == "Y" && pl["p_ctry"] == "대한민국"
                        cont << " - #{pl["p_name"]}"
                    end
                end
                
            else
                hm = (res["h_medal"] != "") ? "#{res["h_medal"]}" : "#{res["h_rank"]} #{res["h_qmark"]}"
                am = (res["a_medal"] != "") ? "#{res["a_medal"]}" : "#{res["a_rank"]} #{res["a_qmark"]}"
                h_me = (hm == "" || hm == " ") ? "" : "(#{hm})"
                a_me = (am == "" || am == " ") ? "" : "(#{am})"
                
                t = "○ #{res["home"]}#{h_me} #{res["homescr"]} : #{res["awayscr"]} #{res["away"]}#{a_me}"
                cont << t
                cont << "○ 참가선수"
                cont << " - #{res["t_name"]}"
            end
            cont << " "
            return cont
        end
        
        def textmake(parsed, menu)

            iceList = ["쇼트트랙", "스피드스케이팅", "아이스 하키", "컬링", "피겨 스케이팅"]
            snowList = ["노르딕 복합", "바이애슬론", "스노보드", "스키점프", "알파인스키", "크로스 컨트리", "프리스타일 스키"]
            sledList = ["봅슬레이", "루지", "스켈레톤"]
            gamestatus = {"BEFORE" => ["경기전","■"], "STARTED" => ["진행중","★"], "RESULT" => ["경기종료","□"]}
            medalList = {"gold"=>"금", "silver"=>"은", "bronze"=>"동"}
            menuList = {"빙상" => iceList, "설원" => snowList, "썰매" => sledList}
            
            target = Array.new
            target = iceList
            textList = Array.new
            
            isYesterday = false
            isSchedule = false
            entry = menu[-2..-1]
            jsondata = parsed["jsonScheduleList"]
            timedata = parsed["jsonLocalDateTimeNow"]
            
            case menu
                when "어제의 경기"
                    textList << " ▶▶ 어제 경기 결과 ◀◀\n"
                when "오늘의 일정"
                    textList << " ▶▶ 2월 #{timedata["dayOfMonth"]}일 전체 일정 ◀◀\n"
                when "내일 평창 일정"
                    tomorrow = timedata["dayOfMonth"] + 1
                    textList << " ◀◀ 2월 #{tomorrow}일 전체 일정 ▶▶\n"
                when "오늘의 빙상" , "오늘의 설원" , "오늘의 썰매"
                    textList << " ▶▶ 2월 #{timedata["dayOfMonth"]}일 #{entry} 경기 ◀◀\n"
                else
                textList << "Menu Error"
            end
            # 정보 처리
            jsondata.each do |data|
                if data["isKorea"] == "Y" # 한국 경기만
            
                    res = Hash.new
                    res = data_parser(data)
                    
                    case menu
                        when "어제의 경기"
                            textList << yesterday_did(res, medalList, type=data["gameType"])
                        when "오늘의 일정", "내일 평창 일정"
                            textList << today_schedule(res, gamestatus, type=data["gameType"])
                        when "오늘의 빙상" , "오늘의 설원" , "오늘의 썰매"
                            target = menuList[entry]
                            if target.include?(res["entry"])
                                textList << today_entry(res, medalList, gamestatus, data["gameType"]) 
                            end
                        else
                        textList << "Menu Error"
                    end
                end
            end
            
            return textList.join("\n")
        end
        
    end
    

end