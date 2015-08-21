
require "affix"

class AffixNav
  constructor: ->
    @el =
      affixContainer: $("#affix-nav")

    @options =
       offset:
         top: 60
         bottom: 60
    @addListeners()

  addListeners: ->
    @el.affixContainer.affix(@options)

module.exports = new AffixNav



