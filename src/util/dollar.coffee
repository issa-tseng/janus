module.exports =
  if typeof window is 'undefined'
    require('jquery')(require('domino').createWindow())
  else
    window.jQuery ? window.Zepto ? window.$

