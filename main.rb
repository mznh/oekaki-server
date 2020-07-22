#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require 'pp'
require 'json'
require 'securerandom'
require "./game_master"

class Faye::WebSocket
  attr_accessor :user_id
end

$connection_pool = {}
$log = []

gm = GameMaster.new()

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, nil, {ping: 15})
    ws.on :open do |event|
      p "connect!"
      id = SecureRandom.hex(8)
      p "generate new id: #{id}"
      # set id
      ws.user_id = id  
      $connection_pool[id] = ws
      print "send log: "
      $log.each do |ms|
        print JSON.parse(ms)["strokeType"].to_s + ","
        ws.send(ms)
      end
      puts ""
    end

    ws.on :message do |event|
      p "recieved from #{ws.user_id}"
      msg = JSON.parse(event.data)
      p "message type: #{msg["strokeType"]}" 
      if msg["strokeType"] == 1 then
        $log = []
      else
        $log << event.data
      end
      $connection_pool.each do |k,wss|
        wss.send(event.data)
      end
    end

    ws.on :close do |event|
      #p [:close, event.code, event.reason]
      p "disconnect #{ws.user_id}"
      $connection_pool.delete(ws.user_id)
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    p env["REQUEST_PATH"]
    path = env["REQUEST_PATH"]
    case path
    when /\/master\/.*/ 
      p "master call"
    else
      p "else path: (#{path})"
    end
    
    [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
  end
end






