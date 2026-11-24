'use strict'

const o = require('ospec')
const commands = require('../src/commands.js')

o('autoTitle', async () => {
  const command = commands.find(c => c.name === 'autoTitle')
  o(command).notEquals(null)

  // console.log(command)
})

o('help - as `.help`', () => {
  const spy = o.spy()
  const command = commands.find(c => c.name === 'help')
  o(command).notEquals(null)

  const mockEvent = {
    message: '.help',
    reply: spy
  }

  command(mockEvent)

  o(spy.calls[0].args[0].includes('Ask me about')).equals(true)
})

o('help - as `.help help`', () => {
  const spy = o.spy()
  const command = commands.find(c => c.name === 'help')
  o(command).notEquals(null)

  const mockEvent = {
    message: '.help help',
    reply: spy
  }

  command(mockEvent)

  o(spy.calls[0].args[0].includes('is called via')).equals(true)
})

o('help - as `.help undefined`', () => {
  const spy = o.spy()
  const command = commands.find(c => c.name === 'help')
  o(command).notEquals(null)

  const mockEvent = {
    message: '.help undefined',
    reply: spy
  }

  command(mockEvent)

  o(spy.calls[0].args[0].includes('know anything about')).equals(true)
})

o('peek - as `.peek key`', async () => {
  const spy = o.spy(_ => 'VALUE')
  const command = commands.find(c => c.name === 'peek')
  o(command).notEquals(null)

  const mockEvent = {
    target: '#test',
    message: '.peek key',
    nick: 'test',
    database: { get: spy },
    reply: spy
  }

  await command(mockEvent)

  o(spy.calls[0].args[0]).equals('key')
  o(spy.calls[1].args[0].includes('VALUE')).equals(true)
})

o('salute - as `v.v.v`', () => {
  const spy = o.spy()
  const command = commands.find(c => c.name === 'salute')
  o(command).notEquals(null)

  const mockEvent = {
    message: 'v.v.v',
    reply: spy
  }

  command(mockEvent)

  o(spy.calls[0]).notEquals(null)
})

o('seen - as `.seen nick`', async () => {
  const spy = o.spy(_ => 'TIME')
  const command = commands.find(c => c.name === 'seen')
  o(command).notEquals(null)

  const mockEvent = {
    target: '#test',
    message: '.seen nick',
    nick: 'test',
    database: { get: spy },
    reply: spy
  }

  await command(mockEvent)

  o(spy.calls[0].args[0]).equals('seen/#test/nick')
  o(spy.calls[1].args[0].includes('TIME')).equals(true)
})

o('tell - as `.tell nick hello`', async () => {
  const spy = o.spy(_ => '[]')
  const command = commands.find(c => c.name === 'tell')
  o(command).notEquals(null)

  const mockEvent = {
    target: '#test',
    message: '.tell nick hello',
    nick: 'test',
    database: { get: spy, put: spy },
    reply: spy
  }

  await command(mockEvent)

  o(spy.calls[0].args[0]).equals('tell/#test/nick')
  o(spy.calls[1].args[0]).equals('tell/#test/nick')
  o(spy.calls[1].args[1]).equals('[{"nick":"test","message":"hello"}]')
  o(spy.calls[2].args[0].includes('pass')).equals(true)
})

o('watch - as anything', async () => {
  const spy = o.spy(_ => JSON.stringify([{ nick: 'test2', message: 'hello' }]))
  const command = commands.find(c => c.name === 'watch')
  o(command).notEquals(null)

  const mockEvent = {
    target: '#test',
    message: 'message',
    nick: 'test',
    database: { put: spy, get: spy, del: spy },
    reply: spy
  }

  await command(mockEvent)

  o(spy.calls[0].args[0]).equals('seen/#test/test')
  o(spy.calls[1].args[0]).equals('tell/#test/test')
  o(spy.calls[2].args[0].includes('hello')).equals(true)
  o(spy.calls[3].args[0]).equals('tell/#test/test')
})
