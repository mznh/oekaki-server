#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require 'pp'


$connection_pool = {}
$log = []

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, nil, {ping: 15})
    @id = $connection_pool.length
    ws.on :open do |event|
      p "connect!"
      $connection_pool[@id] = ws
      p $connection_pool.length
      p "send log"
      $log.each do |ms|
        ws.send(ms)
      end
    end

    ws.on :message do |event|
      $log << event.data
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

