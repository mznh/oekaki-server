require 'thin'
require './main'

Faye::WebSocket.load_adapter('thin')

run App#
