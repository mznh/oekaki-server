#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require 'pp'
require 'json'
require 'securerandom'
require "./game_master"

class Faye::WebSocket
  attr_accessor :user_id, :user_name
end


gm = GameMaster.new()

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, nil, {ping: 15})
    ws.on :open do |event|
      p "connect!"
      new_user_id = SecureRandom.hex(8)
      p "generate new id: #{new_user_id}"
      # set id
      ws.user_id = new_user_id  
      gm.add_connection(new_user_id, ws)
      p "send log: "
      gm.send_log(new_user_id)
    end

    ws.on :message do |event|
      p "recieved from #{ws.user_id}"
      json = JSON.parse(event.data)
      action = OekakiAction.newFromJSON(json)
      p "message type: #{action.type}" 
      ##TODO こここの処理を後々game_master側に移す
      case action.type
      when ActionType::CLEAR then
        gm.clear_log
      when ActionType::WRITE then
        p action.color
        ## paint logを記録
        gm.record_log action
        gm.broadcast_message(action)
      when ActionType::CHAT then
        ## message logを記録
        ## 今は同じ場所に記録
        gm.record_log action
        # 答えをチャレンジしておく
        gm.challenge_answer(ws.user_id, action.message)
        gm.broadcast_message(action)
      else
      end
    end

    ws.on :close do |event|
      #p [:close, event.code, event.reason]
      p "disconnect #{ws.user_id}"
      gm.connection_pool.delete(ws.user_id)
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    p env["REQUEST_PATH"]
    path = env["REQUEST_PATH"]
    case path
    when /\/master\/clear/ 
      p "master call"
      p path
      act = OekakiAction.new(ActionType::CLEAR)
      gm.clear_log()
    when /\/master\/call\/(.*)/ 
      p "master call"
      p path
      act = OekakiAction.new(ActionType::ANNOUNCE)
      act.message = "#{$1}"
      puts act.to_msg
      gm.broadcast_message(act.to_msg)
    when /\/master\/start/
      gm.game_start()
    else
      p "else path: (#{path})"
    end
    
    [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
  end
end


