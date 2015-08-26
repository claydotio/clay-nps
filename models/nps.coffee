module.exports = class Nps
  constructor: ({@cookieSubject, @proxy, @config}) -> null

  create: ({gameKey, score, comment, email}) =>
    @proxy @config.CLAY_API_URL + '/nps',
      method: 'POST'
      body:
        gameKey: gameKey
        score: score
        comment: comment
        email: email
        userAgent: navigator.userAgent
      qs: {accessToken: @cookieSubject.getValue()[@config.AUTH_COOKIE]}
