# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@bindTagsFunctionality = ->
  $('[class^=\'tag\'').click (e) ->
    e.preventDefault()
    $(this).toggleClass 'active'
    applyTags()
  $('#unselect-all').click ->
    $('.wrapper-tags .active').toggleClass('active')
    $("#all-styles .styles").children().show()
  applyTags()
  return

@applyTags = ->
  $("#all-styles .styles").children().hide()
  tags = new Array()
  $('.wrapper-tags .active').each (i) ->
    tags.push $(@).data('tag').split(' ').join('-')
    return
  tags = tags.join(".")
  if tags.length > 0
    $("#all-styles .styles").find("." + tags).show()
  else
    $("#all-styles .styles").children().show()
  return

@loadProcessedImage = ->
  loadingElements = $(".queue-image-item[data-loading]")
  if loadingElements.length > 0
    intervals = new Array()
    loadingElements.each (i) ->
      elem = @
      interval = setInterval((->
        $.get('/queue_images/' + $(elem).data('item-id') + '/loaded').success((data) ->
          clearInterval interval
          return
        )
        return
      ), 15000)
      intervals.push(interval)
      return
    $(document).on 'turbolinks:click', ->
      intervals.forEach (elem) ->
        clearInterval elem
        return
      return
  return

@markStyle = (e) ->
  id = $(@).data 'style-id'
  $('[class^="mark_style_"]').html ''
  $('.mark_style_' + id).html '<div class="marked"><img src="/check.png" class="imagesStyle"</div>'
  $('input[name="queue_image[style_id]"').val id
  return

@markQueueImage = (e) ->
  id = $(@).data 'my-image-id'
  $('.my-image-block').removeClass 'active'
  $(@).addClass 'active'
  $('input[name="queue_image[content_id]"').val id
  return

# ---- CANVAS PART ----

offsetX = undefined
offsetY = undefined
startX = undefined
startY = undefined
finishX = undefined
finishY = undefined
ctx = undefined
isDrawing = false
image = undefined
rw = undefined
rh = undefined

@uploadLink = (e) ->
  e.preventDefault()
  $("#slicing-image-field").click()
  return

@initCanvas = (elem, width, height) ->
  elem.attr 'width', width
  elem.attr 'height', height
  canvas = document.getElementById("canvas");
  ctx = canvas.getContext("2d");
  ctx.strokeStyle = "red"
  ctx.drawImage image[0], 0, 0, width, height
  canvasOffset = $('#canvas').offset()
  offsetX = canvasOffset.left
  offsetY = canvasOffset.top
  return

@slicedImageUploaded = (e) ->
  image = $("<img/>")
  $("#crp").attr('src', window.URL.createObjectURL(this.files[0])).load ->
    image.attr('src', $("#crp").attr('src')).load ->
      rh = this.height
      rw = this.width
      image[0].w = w = $("#crp").width()
      image[0].h = h = $("#crp").height()
      initCanvas $("#canvas"), w, h
      $("#crp").remove()
      return
    return
  return

@canvasMouseUp = (e) ->
  finishX = parseInt(e.clientX - offsetX)
  finishY = parseInt(e.clientY - offsetY)
  isDrawing = false
  canvas.style.cursor = 'default'
  $("#submit-original-slicing-image").removeClass 'hidden'
  return

@canvasMouseMove = (e) ->
  if isDrawing
    mouseX = parseInt(e.clientX - offsetX)
    mouseY = parseInt(e.clientY - offsetY)
    ctx.drawImage image[0], 0, 0, image[0].w, image[0].h
    ctx.beginPath()
    finishX = mouseX - startX
    finishY = mouseY - startY
    ctx.rect startX, startY, finishX, finishY
    ctx.stroke()
  return

@canvasMouseDown = (e) ->
  canvas.style.cursor = 'crosshair'
  isDrawing = true
  startX = parseInt(e.clientX - offsetX)
  startY = parseInt(e.clientY - offsetY)
  return

@submitOriginalSlicingImage = (e) ->
  e.preventDefault()
  topX = Math.min(startX, finishX) * (rw / image[0].w)
  topY = Math.min(startY, finishY) * (rh / image[0].h)
  bottomX = Math.max(startX, finishX) * (rw / image[0].w)
  bottomY = Math.max(startY, finishY) * (rh / image[0].h)
  $("#original-image-top-x").val Math.floor(topX)
  $("#original-image-top-y").val Math.floor(topY)
  $("#original-image-bottom-x").val Math.floor(bottomX)
  $("#original-image-bottom-y").val Math.floor(bottomY)
  $('#slice-by-rectangle-form').submit()
  return

# ---- /CANVAS PART ----

$(document).on 'turbolinks:load', bindTagsFunctionality
$(document).on 'turbolinks:load', loadProcessedImage
$(document).on 'click', '.style-block', markStyle
$(document).on 'click', '.my-image-block', markQueueImage

$(document).on 'click', '#upload-slice-image', uploadLink
$(document).on 'change', '#slicing-image-field', slicedImageUploaded
$(document).on 'mouseup', '#canvas', canvasMouseUp
$(document).on 'mousemove', '#canvas', canvasMouseMove
$(document).on 'mousedown', '#canvas', canvasMouseDown
$(document).on 'click', '#submit-original-slicing-image', submitOriginalSlicingImage