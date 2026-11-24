'use strict'

const autoTitle = (event) => {
  const fun = async () => {
    const { groups: { url } } = autoTitle.__match__.exec(event.message)
    const title = await event.fetchTitle(url)

    if (title) {
      const domain = new URL(url).host
      event.reply(`[ ${title} ] - ${domain}`)
    }

    return true
  }

  return fun()
}
autoTitle.__match__ = /.*(?<url>https?:\/\/\S+).*/g

const autoInviteInfo = (event) => {
  const fun = async () => {
    try {
      const lastJoined = await event.database.get(`lastJoined/${event.target}/${event.nick}`);

      if (Date.now() - Date.parse(lastJoined) < 600000) {
        event.reply(`Looking for an invitation ${event.nick}? ` +
          "https://lobste.rs/about#invitations " +
          "has an intro, and " +
          "https://lobste.rs/chat " +
          "explains some expectations for this channel. " +
          "(I am the channel bot.)"
        )
      }
    } catch(e) {
      if (e.notFound) {
        /* bot missed a channel join, default to now, then re-trigger */
        try {
          await event.database.put(`lastJoined/${event.channel}/${event.nick}`, new Date().toString())
          autoInviteInfo(event);
        } catch (e) {
          event.logger.error(e)
        }
      } else {
        event.logger.error(e)
      }
    }
  }

  fun()
}
autoInviteInfo.__match__ = /.*invit(e|ation)s?.*/gm

const help = (event) => {
  const { groups: { query } } = help.__match__.exec(event.message)

  if (query === undefined) {
    const topics = module.exports.map(command => `\`${command.name}\``)

    event.reply(`Ask me about ${topics.join(', ')} via \`.help <command>\`.`)
  } else {
    const subject = module.exports.find(command => command.name === query)

    if (subject) {
      event.reply(`\`${subject.name}\` is called via \`${subject.__match__}\`.`)
    } else {
      event.reply(`I don't know anything about \`${query}\`.`)
    }
  }
}
help.__match__ = /^\.help ?(?<query>\S+)?/

const peek = (event) => {
  const fun = async () => {
    const { groups: { key } } = peek.__match__.exec(event.message)

    try {
      const value = await event.database.get(key)
      event.reply(value)
    } catch (e) {
      if (e.notFound) {
        event.reply('Not Found.')
      } else {
        event.logger.error(e)
      }
    }

    return true
  }

  return fun()
}
peek.__match__ = /^\.peek (?<key>\S+)/

const salute = (event) => {
  const leaves = ['(V)', '(\\/)', '(\\_/)', 'V', 'v', '(v)']
  const stems = ['_!_!_', '.v.', '_00_']

  const leaf = leaves[~~(Math.random() * leaves.length)]
  const stem = stems[~~(Math.random() * stems.length)]

  event.reply(`${leaf}${stem}${leaf}`)
}
salute.__match__ = /^V.v.V/i

const seen = (event) => {
  const fun = async () => {
    const { groups: { user } } = seen.__match__.exec(event.message)

    try {
      const lastSeen = await event.database.get(`seen/${event.target}/${user}`)

      event.reply(`I last saw ${user} in ${event.target} at ${lastSeen}.`)
    } catch (e) {
      if (e.notFound) {
        event.reply(`I haven't seen ${user} in ${event.target}.`)
      } else {
        event.logger.error(e)
      }
    }

    return true
  }

  return fun()
}
seen.__match__ = /^\.seen (?<user>\S+)/g

const tell = (event) => {
  const fun = async () => {
    const { groups: { user, message } } = tell.__match__.exec(event.message)
    const newMessage = { nick: event.nick, message }

    try {
      const rawTells = await event.database.get(`tell/${event.target}/${user}`)
      const tells = JSON.parse(rawTells)

      tells.push(newMessage)
      await event.database.put(`tell/${event.target}/${user}`, JSON.stringify(tells))
    } catch (e) {
      if (e.notFound) {
        await event.database.put(`tell/${event.target}/${user}`, JSON.stringify([newMessage]))
      } else {
        event.logger.error(e)
      }
    }

    event.reply(`I'll pass it along next time I see ${user}.`)
  }

  return fun()
}
tell.__match__ = /^\.tell (?<user>\S+) (?<message>.+)/g

const watch = (event) => {
  const fun = async () => {
    await event.database.put(`seen/${event.target}/${event.nick}`, new Date().toString())

    try {
      const rawTells = await event.database.get(`tell/${event.target}/${event.nick}`)
      const tells = JSON.parse(rawTells)

      tells.forEach(tell => event.reply(`${event.nick}: ${tell.message} (from ${tell.nick}).`))
    } catch (e) {
      if (e.notFound) {
        // do nothing
      } else {
        event.logger.error(e)
      }
    } finally {
      await event.database.del(`tell/${event.target}/${event.nick}`)
    }

    return true
  }

  return fun()
}
watch.__match__ = /^.+/g

module.exports = [
  autoTitle,
  autoInviteInfo,
  help,
  peek,
  salute,
  seen,
  tell,
  watch
]
