###
  Author: Jinhyuk Lee
###

jQuery ->
  $.extend {
    getParameters: () ->
      vars = []
      if window.location.hash.indexOf('?') is -1
        return []
      for hash in window.location.hash.slice(window.location.hash.indexOf('?') + 1).split('&')
        continue if hash.length is 0
        kv = hash.split('=')
        vars.push kv[0]
        vars[kv[0]] = kv[1]
      return vars
    getParameter: (name) ->
      temp = $.getParameters()[name]
      if temp is undefined
        ""
      else
        temp

    getParameterHash: () ->
      if window.location.hash.indexOf('?') == -1 
        return ""
      else
        window.location.hash.slice(window.location.hash.indexOf('?'))

    setParameter: (key, value) ->
      if $.getParameter(key) is undefined
        if window.location.hash.indexOf('?') is -1
          window.location.hash += "?"
        window.location.hash += key + '=' + value + '&'
      else
        params = $.getParameters
        temp = "?"
        for p in params
          temp += p + '=' + params[p] + '&'
        temp += key + '=' + value + '&'
        window.location.hash = window.location.hash.slice(0, window.location.hash.indexOf('?')) + temp
      $('#submenu li.active').data('parameter', $.getParameterHash())
  }

  $body = $('body')

  event =
    afterLoad: () ->
      logo = $('#animation-mask #logo')
      if mint.doneLoading is true
        if mint.waitForLoading is true
          if logo.is(':hidden')
            logo.fadeIn 1000, 'easeInQuint', (e) ->
              event.afterLoad()
          else
            setTimeout event.afterLoad, 500
        else
          logo.hide()
          $('#single-page div.modal').animate {marginTop: '15.5px'}, 1000, 'easeOutQuint'
          $('#animation-mask').fadeOut {
            duration: 1000
            easing: 'easeOutQuint'
          }
      else
        if logo.is(':hidden')
          logo.fadeIn 1000, 'easeInQuint', (e) ->
            event.afterLoad()
        else
          setTimeout event.afterLoad, 500
      true

  mint.waitForLoading = false if mint.waitForLoading is undefined
  mint.doneLoading = false if mint.doneLoading is undefined
  mint.loadingInterval = 60 * 3

  $meta = $('meta[name=animation]')
  if $meta.length > 0 and $meta isnt undefined
    content = $meta[0].getAttribute('content')
    if content is "fadein"
      color = if $('#single-page').is('.white') then 'white' else 'black'
      $body.append """
        <div id="animation-mask" class="#{color}">
          <div id="logo" class="hide #{color}"></div>
        </div>
      """
      $('#single-page').show()
      $(window).load (e) ->
        mint.doneLoading = true
        event.afterLoad()

  onBlock = ($block) ->
    state = $block.data('state')
    if state is 0
      $block.data 'state', Math.round(Date.now()/1000)

    $block.addClass('active').fadeIn {
        duration: 300
        easing: 'easeOutQuint'
      }

  offContent = ($content) ->
    $content.find('div.active').fadeOut {
      duration: 300
      easing: 'easeOutQuint'
    }

  onMenu = ($submenu, $menu) ->
    $submenu.find('li:not(.reactive)').removeClass('active')
    $menu.addClass('active')
    if $submenu.data('parameter') is undefined
      $submenu.data('parameter', '')
    document.location.hash = '!/' + $menu.data('menu') + $.getParameterHash()

  triggerContent = ($content, $submenu, $menu, callback) ->
    $block = $content.find("[data-content=#{ $menu.data('menu') }]")
    if $menu.is('.active')
      return true

    if $menu.is('.reactive')
      $menu.removeClass('reactive')
    else
      offContent $content

    onMenu $submenu, $menu

    state = $block.data('state')
    if state is 0 or state < Math.round(Date.now()/1000) - mint.loadingInterval
      callback $block
    else
      onBlock $block
    true

  refreshContent = ($content, $submenu, block, callback) ->
    $block = $content.find("[data-content=#{ block }]")
    $block.data('state', 0)
    el = $submenu.find "[data-menu=#{ block }]"
    if el.length > 0
      el.removeClass 'active'
      el.addClass 'reactive'
      el.trigger 'click'
      callback $block
    else
      console.log "Invalid data-menu=? at method refreshContent"

  triggerIndex = ($content, callback) ->
    $block = $content.find('[data-content=index]')
    offContent $content
    $submenu.find('li').removeClass('active')

    state = $block.data('state')
    if state is 0 or state < Math.round(Date.now()/1000) - mint.loadingInterval
      callback $block
    else
      onBlock $block
    true

  triggerHash = ($content, $submenu) ->
    path = document.location.pathname
    if $.getParameterHash().length > 0
      hash = window.location.hash.slice(3, window.location.hash.indexOf('?'))
    else
      hash = window.location.hash.slice(3)

    menu = $('#menu li.active').data('menu')

    if hash is undefined or hash.length is 0
      triggerIndex $content, ($block) ->
        routes.controllers.Panel[menu + '_index'](mint.id)
          .ajax()
          .success (e) ->
            $block.html e
            onBlock $block
    else if path.charAt(path.length - 1) is "/"
      el = $submenu.find "[data-menu=#{ hash }]"
      $submenu.data('data-parameter', $.getParameterHash())
      if el.length > 0
        el.trigger 'click'
      else
        console.log "Invalid data-menu='#{hash}' at method triggerHash"
        document.location.hash = '!/index' + $.getParameterHash()
        triggerIndex $content, ($block) ->
          routes.controllers.Panel[menu + '_index'](mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block
    else
      false

  $meta = $('meta[name=panel]')
  if $meta.length > 0 and $meta isnt undefined
    mint.page = $meta[0].getAttribute('content')

    if mint.page is 'overview'
      $submenu = $("#submenu")
      $content = $("#content")

      $submenu.find('[data-menu=usage]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_usage(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=account]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_account(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=transaction]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_transaction(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=api]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_api(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              $block.find('div.well span').html mint._api.token
              $block.find('textarea').html mint._api.urls.join '\n'
              $form = $block.find('form#domain')
              $form.submit () ->
                offContent $content
                args =
                  data: {
                    domain: $form.find('textarea[name=domain]').val()
                  }
                  success: (e) ->
                    refreshContent $content, $submenu, 'api', ($block) ->
                      true

                routes.controllers.Panel.overview_api_set(mint.id).ajax args
                return false
              
              onBlock $block

      triggerHash $content, $submenu
      mint.waitForLoading = false
    else if mint.page is 'data'
      $submenu = $("#submenu")
      $content = $("#content")

      $submenu.find('[data-menu=view]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_view(mint.id, $.getParameter('_filter'))
            .ajax()
            .success (e) ->
              $block.html e
              $block.find('input[name=s]').typeahead { source: mint._types }
              $block.find('input[name=o]').typeahead { source: mint._types }
              $block.find('#selector div.custom-filter a.add').tooltip {title: "Add new filter"}

              $revert = $block.find('#revert')
              if $.getParameter("_filter").length > 0
                $revert.click () ->
                  $.setParameter "_filter", ""
                  refreshContent $content, $submenu, 'view', ($block) ->
                    true
              else
                $revert[0].disabled = 'disabled'
              
              $refresh = $block.find('#refresh')
              $refresh.click () ->
                refreshContent $content, $submenu, 'view', ($block) ->
                  true

              if mint._points isnt undefined and mint._points.points.length > 0
                $tbody = $block.find('table#points')
                for p in mint._points.points
                  d1 = moment(p.createdAt).format('YYYY-MM-DD HH:mm:ss')
                  d2 = moment(p.createdAt).fromNow()
                  d = JSON.stringify(p.data)
                  if d is "{}"
                    d = "<small> - </small>"
                  $tbody.prepend """
                    <tr>
                      <td><a href="#{p._url}">#{p.id}</a></td>
                      <td>#{p.type}</td>
                      <td>#{p.identifier}</td>
                      <td class="code">#{d}</td>
                      <td>
                        <time datetime="#{d1}" title="#{d1}">#{d2}</time>
                      </td>
                    </tr>
                    """
                $tbody.fadeIn()
              else if mint._edges isnt undefined and mint._edges.edges.length > 0
                $tbody = $block.find('table#edges')
                for e in mint._edges.edges
                  d1 = moment(e.createdAt).format('YYYY-MM-DD HH:mm:ss')
                  d2 = moment(e.createdAt).fromNow()
                  ### currently not support data store in an edge.
                  d = JSON.stringify(e.data)
                  if d is "{}"
                    d = "<small> - </small>"
                  ###
                  d = "<small> - </small>"
                  $tbody.prepend """
                    <tr>
                      <td>
                        <span class="label label-inverse">#{e.subjectType}</span>
                        <span class="label label-info">#{e.subjectId}</span>
                      </td>
                      <td>#{e.verb}</td>
                      <td>
                        <span class="label label-inverse">#{e.objectType}</span>
                        <span class="label label-info">#{e.objectId}</span>
                      </td>
                      <td class="code">#{d}</td>
                      <td>
                        <time datetime="#{d1}" title="#{d1}">#{d2}</time>
                      </td>
                    </tr>
                    """
                $tbody.fadeIn()
              
              $modelForm = $block.find('form#model')
              $modelForm.submit () ->
                offContent $content
                $block.find('table').hide()

                `delete mint._points`
                `delete mint._edges`

                query = {
                  s: $modelForm.find('input[name=s]').val()
                  v: $modelForm.find('input[name=v]').val()
                  o: $modelForm.find('input[name=o]').val()
                }
                
                $.setParameter "_filter", JSON.stringify query

                refreshContent $content, $submenu, 'view', ($block) ->
                  true

              $relForm = $block.find('form#relation')

              onBlock $block

      $submenu.find('[data-menu=filter]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_filter(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=import]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_import(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block
              $block.find('input[name=model]').typeahead { source: mint._sTypes }
              $form = $block.find('form#model')
              $form.submit () ->
                args =
                  data: {
                    model: $form.find('input[name=model]').val()
                    identifier: $form.find('input[name=identifier]').val()
                    data: $form.find('textarea[name=data]').val()
                  }
                  success: (e) ->
                    refreshContent $content, $submenu, 'import', ($block) ->
                      true
                      
                try
                  if args.data.data.length > 0
                    JSON.parse args.data.data
                catch error
                  $form.find('span.help-block').html "JSON 데이터가 유효하지 않습니다: " + error.toString()
                  return false
                
                offContent $content
                routes.controllers.Panel.data_import_add(mint.id).ajax args
                return false
              $block.find('time').each (k,v) ->
                $time = $(v)
                $time.html moment($time.html()).fromNow()

      $submenu.find('[data-menu=export]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_export(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block

      triggerHash $content, $submenu
      mint.waitForLoading = false
      mint.triggerContentWith = (name, json) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel['data_' + name](mint.id, JSON.stringify(json))
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block
    else if mint.page is 'support'
      $submenu = $("#submenu")
      $content = $("#content")

      console.log ">>>", mint.page
      $submenu.find('[data-menu=conversation]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.support_conversation(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=consulting]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.support_consulting(mint.id)
            .ajax()
            .success (e) ->
              $block.html e
              onBlock $block

      triggerHash $content, $submenu
      mint.waitForLoading = false
    else
      alert("페이지를 불러올 수 없습니다. ")

  $meta = $('meta[name=document]')
  if $meta.length > 0 and $meta isnt undefined
    mint.page = $meta[0].getAttribute('content')
    $body = $('#document #body')
    $body.find('time.updatedAt').each (k,v) ->
      $this = $(v)
      $this.html moment($this.html(), "YYYY-MM-DD").fromNow()

    if mint.page is 'javascript/api'
      $code = $('div#body textarea.code');
      $code.val($code.val().replace("YOUR API KEY HERE", mint._api.token + '::' + mint.id))


  $meta = $('meta[name=login]')
  if $meta.length > 0 and $meta isnt undefined
    mint.page = $meta[0].getAttribute('content')

    if mint.page is 'changeAccount'
      $link = $('#link')
      l = $link.html() + location.hash
      $link.html l
      $link[0].href = l
