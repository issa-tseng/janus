module.exports =
  if typeof window is 'undefined'
    require('zepto-node')(require('domino').createWindow())
  else
    window.jQuery ? window.Zepto ? window.$

