$(document).ready ->
  $('#document-content').replaceWith("<%= escape_javascript render('documents/questions/new', question: Question.new) %>")

  $('.well-active').attr class: 'well'
  $('#document-<%= @document.id %>').attr class: 'well well-active'
  $('#document-content').css 'margin-top', $('#document-<%= @document.id %>').position().top

  $('#flash').remove()
  $('#main-container').prepend("<%= escape_javascript render('shared/flash_messages', messages: flash_to_messages) %>")

  fixes()

  new Select()
