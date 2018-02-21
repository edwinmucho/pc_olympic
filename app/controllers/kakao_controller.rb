require 'msgmaker'
require 'parser'

class KakaoController < ApplicationController
  @@key = Msgmaker::Keyboard.new
  @@msg = Msgmaker::Message.new
  
  def keyboard
    render json: @@key.getBtnKey(["어제의 경기","오늘의 일정","오늘의 빙상","오늘의 설원","오늘의 썰매","순위","내일 평창 일정"])
  end
  
  def message
    user_msg = params[:content] 
    basic_keyboard = @@key.getBtnKey(["어제의 경기","오늘의 일정","오늘의 빙상","오늘의 설원","오늘의 썰매","순위","내일 평창 일정"])
    
    pic = false

    today = Time.now.getlocal('+09:00')
    
    day = today.mday
    mday = "%02d" % day
    
    case user_msg
      when "어제의 경기"
        game = Parser::Game.new
        mday = "%02d" % (day - 1)
        msg = game.Info(mday,user_msg)
      when "오늘의 일정"
        game = Parser::Game.new
        msg = game.Info(mday,user_msg)
        # msg = "오늘의경기출력"
      when "오늘의 설원" , "오늘의 빙상" , "오늘의 썰매"
        game = Parser::Game.new
        msg = game.Info(mday,user_msg)
      when "순위"
        rank = Parser::Game.new
        msg = rank.Rank
      when "내일 평창 일정"
        game = Parser::Game.new
        mday = "%02d" % (day + 1)
        msg = game.Info(mday,user_msg)
      else
        msg = "평창 가즈아"
    end
    
    if pic
      result = {
        message: @@msg.getPicMessage(msg.to_s, url),
        keyboard: basic_keyboard
      }
    else
      result = {
        message: @@msg.getMessage(msg.to_s),
        keyboard: basic_keyboard
      }
    end
    render json: result
  end
  
  def friend_add
    user_key = params[:user_key]
    #새로운 유저를 저장해주세요
    render nothing: true
  end
  
  def friend_add
    User.create(user_key: params[:user_key], chat_room: 0)
    render nothing: true
  end
  
  def chat_room
    user = User.find_by(user_key: params[:user_key])
    user.plus
    user.save
    render nothing: true
  end
  
end
  