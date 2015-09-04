module.exports = class Nps
  constructor: ({@auth, @config}) -> null

  create: ({gameKey, score, comment, email}) =>
    @auth.fetch @config.CLAY_API_URL + '/nps',
      method: 'POST'
      body:
        gameKey: gameKey
        score: score
        comment: comment
        email: email
        userAgent: navigator.userAgent
