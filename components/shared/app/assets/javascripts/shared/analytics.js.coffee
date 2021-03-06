class window.Analytics
  @bind: ->
    $(document).ready ->
      $('[data-track-category]').click ->
        category = $(this).attr 'data-track-category'
        action   = $(this).attr 'data-track-action'

        if $(this).attr 'data-track-label'
          label = $(this).attr 'data-track-label'
        else
          label = $(this).attr 'id' ? $(this).attr 'id' : nil

        _gaq?.push ['_trackEvent', category, action, label]
