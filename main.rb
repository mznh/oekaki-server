#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require 'pp'
require 'json'


$connection_pool = {}
$log = []

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, nil, {ping: 15})
    @id = $connection_pool.length
    ws.on :open do |event|
      p "connect!"
      $connection_pool[@id] = ws
      p @id
      p "send log"
      $log.each do |ms|
        print JSON.parse(ms)["strokeType"].to_s + ","
        ws.send(ms)
      end
      puts ""
    end

    ws.on :message do |event|
      msg = JSON.parse(event.data)
      p msg["strokeType"] 
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
      $connection_pool.delete(@id)
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
  end
end

