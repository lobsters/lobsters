// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

"use strict";

import "autosize"

import "TomSelect"
import "TomSelect_remove_button"
import "TomSelect_caret_position"
import "TomSelect_input_autogrow"

const csrfToken = () => {
  return qS('meta[name="csrf-token"]').getAttribute('content');
}

function on(eventTypes, selector, callback) {
  eventTypes.split(/ /).forEach( (eventType) => {
    document.addEventListener(eventType, event => {
      if (event.target.matches(selector)) {
        callback(event);
      }
    });
  });
}

const onPageLoad = (callback) => {
  document.addEventListener('DOMContentLoaded', callback);
};

const parentSelector = (target, selector) => {
  let parent = target;
  while (!parent.matches(selector)) {
    parent = parent.parentElement;
    if (parent === null) {
      throw new Error(`Did not match a parent of ${target} with the selector ${selector}`);
    }
  }
  return parent;
};

const qS = (context, selector) => {
  if (selector === undefined) {
    selector = context;
    context = document;
  }
  return context.querySelector(selector);
};

const qSA = (context, selector) => {
  if (selector === undefined) {
    selector = context;
    context = document;
  }
  return context.querySelectorAll(selector);
};

const replace = (oldElement, newHTMLString) => {
  const placeHolder = document.createElement('div');
  placeHolder.insertAdjacentHTML('afterBegin', newHTMLString);
  const newElements = placeHolder.childNodes.values();
  oldElement.replaceWith(...newElements);
  removeExtraInputs();
}

const slideDownJS = (element) => {
  if (element.classList.contains('slide-down'))
    return;

  element.classList.add('slide-down');
  const cs = getComputedStyle(element);
  const paddingHeight = parseInt(cs.paddingTop) + parseInt(cs.paddingBottom);
  const height = (element.clientHeight - paddingHeight) + 'px';
  element.style.height = '0px';
  setTimeout(() => { element.style.height = height; }, 0);
};

const fetchWithCSRF = (url, params) => {
  params = params || {};
  params['headers'] = params['headers'] || new Headers;
  params['headers'].append('X-CSRF-Token', csrfToken());
  params['headers'].append('X-Requested-With', 'XMLHttpRequest'); // request.xhr?
  return fetch(url, params);
}

const removeExtraInputs = () => {
  // This deletion will resolve a bug that creates an extra hidden input when rendering the comment elements
  const extraInputs = qSA('.comment_folder_button + .comment_folder_button');
  for (const i of extraInputs) {
    i.remove();
  }
}

class _LobstersFunction {
  constructor (username) {
    this.curUser = null;

    this.storyFlagReasons = JSON.parse(qS('meta[name="story-flags"]').getAttribute('content'));

    this.commentFlagReasons = JSON.parse(qS('meta[name="comment-flags"]').getAttribute('content'));
  }

  bounceToLogin() {
    document.location = "/login?return=" + encodeURIComponent(document.location);
  }

  modalFlaggingDropDown(flaggedItemType, voterEl, reasons) {
    if (!Lobster.curUser) return Lobster.bounceToLogin();

    const li = parentSelector(voterEl, '.story, .comment');
    if (li.classList.contains('flagged')) {
      /* already upvoted, neutralize */
      if (li.classList.contains('story')) {
        Lobster.voteStory(voterEl, -1, null);
      } else {
        Lobster.voteComment(voterEl, -1, null);
      }
      return
    }

    if (qS('#flag_dropdown') || qS('#modal_backdrop')) {
      Lobster.removeFlagModal()
    }

    const modalDiv = document.createElement("div");
    modalDiv.setAttribute('id', 'modal_backdrop');
    document.body.appendChild(modalDiv);

    const flaggingDropDown = document.createElement('div');
    flaggingDropDown.setAttribute('id', 'flag_dropdown');
    voterEl.after(flaggingDropDown);

    Object.keys(reasons).map(function(k, v) {
      let a = document.createElement('a')
      a.textContent = reasons[k]
      a.setAttribute('data', k)
      a.setAttribute('href', '#')
      if (k === '') {
        a.classList.add('cancel-reason')
      }
      flaggingDropDown.append(a);
    });
  }

  checkStoryDuplicate(form) {
    const formData = new FormData(form);
    const action = '/stories/check_url_dupe';
    fetchWithCSRF(action, {
      method: 'post',
      headers: new Headers({'X-Requested-With': 'XMLHttpRequest'}),
      body: formData,
    }).then (response => {
      response.text().then(text => {
        // FIXME on second click of 'fetch title', this doesn't run
        qS('.form_errors_header').innerHTML = text;
      });
    });
  }

  checkStoryTitle() {
    const titleLocation = qS('#story_title');
    if (!titleLocation) return;

    const title = titleLocation.value;
    if (!title) return;

    // Check for common prefixes like "ask lobsters:", remove it, and add the appropriate tag
    const m = title.match(/^(show|ask) lobste\.?rs:? (.+)$/i);
    if (m) {
      const titleEl = qS('#story_title');
      Lobster.tom.addItem(m[1].toLowerCase());
      titleEl.value = m[2];
    }

    // common separators or (parens) that don't enclose a 4-digit year
    if (title.match(/: | - | – | — | \| | · | • | by /) ||
       (title.match(/\([^\)]*\)/g) || []).some(function (p) { return !p.match(/\(\d{4}\)/) })) {
          slideDownJS(qS('.title-reminder'));

    // else if the title doesn't contain concerns and reminder is visible
    } else if (qS('.title-reminder').classList.contains('slide-down')) {
      qS('.title-reminder-thanks').style.display = 'inline';
    }
  }

  fetchURLTitle(button) {
    const url_field = qS('#story_url');
    const targetUrl = url_field.value;
    const title_field = qS('#story_title');
    const formData = new FormData();
    const old_text = button.textContent;

    if (targetUrl == "")
      return;

    button.setAttribute("disabled", true);
    button.textContent = "Fetching...";
    formData.append('fetch_url', targetUrl);

    fetchWithCSRF('/stories/fetch_url_attributes', {
      method: 'post',
      headers: new Headers({'X-Requested-With': 'XMLHttpRequest'}),
      body: formData,})
      .then (response => response.json())
      .then (data => {
        title_field.value = data.title
        if (url_field.value != data.url) {
          slideDownJS(qS('.url-updated'));
        }
        url_field.value = data.url
        button.textContent = old_text
      });
    button.removeAttribute("disabled");
    Lobster.checkStoryTitle();
  }

  hideStory(hiderEl) {
    if (!Lobster.curUser) return Lobster.bounceToLogin();

    const li = parentSelector(hiderEl, ".story, .comment");
    let act;
    if (li.classList.contains("hidden")) {
      act = "unhide";
      li.classList.remove("hidden");
      hiderEl.innerHTML = "hide";
    } else {
      act = "hide";
      li.classList.add("hidden");
      hiderEl.innerHTML = "unhide";
    }
    fetchWithCSRF("/stories/" + li.getAttribute("data-shortid") + "/" + act, {method: 'post'});
  }

  removeFlagModal() {
    qS('#flag_dropdown').remove();
    qS('#modal_backdrop').remove();
  }

  postComment(form) {
    const formData = new FormData(form);
    const action = form.getAttribute('action');
    formData.append('show_tree_lines', true);
    fetchWithCSRF (action, {
      method: 'post',
      headers: new Headers({'X-Requested-With': 'XMLHttpRequest'}),
      body: formData
    })
      .then(response => {
        response.text().then(text => replace(form.parentElement, text));
      })
  }

  previewComment(form) {
    const formData = new FormData(form);
    const action = form.getAttribute('action');
    formData.append('preview', 'true');
    formData.append('show_tree_lines', 'true');
    fetchWithCSRF(action, {
      method: 'post',
      headers: new Headers({'X-Requested-With': 'XMLHttpRequest'}),
      body: formData
    })
      .then(response => {
        response.text().then(text => {
          replace(form.parentElement, text);
          autosize(qSA('textarea'));
        });
      });
  }

  previewStory(formElement) {
    if (!Lobster.curUser) return Lobster.bounceToLogin();

    const formData = new FormData(formElement);
    const previewElement = qS('#inside');
    fetchWithCSRF('/stories/preview', {
      method: 'post',
      headers: new Headers({'X-Requested-With': 'XMLHttpRequest'}),
      body: formData
    }).then(response => {
      response.text().then(text => {
        previewElement.innerHTML = text;
        Lobster.tomSelect();
      });
    });
  }

  saveStory(saverEl) {
    if (!Lobster.curUser) return Lobster.bounceToLogin();

    const li = parentSelector(saverEl, ".story, .comment");
    let act;

    if (li.classList.contains("saved")) {
      act = "unsave";
      li.classList.remove("saved");
      saverEl.innerHTML = "save";
    } else {
      act = "save";
      li.classList.add("saved");
      saverEl.innerHTML = "unsave";
    }
    fetchWithCSRF("/stories/" + li.getAttribute("data-shortid") + "/" + act, {method: 'post'});
  }

  tomSelect(item) {
    if (!qS('#story_tags')) {
      return
    }

    TomSelect.define('caret_position', caret_position);
    TomSelect.define('input_autogrow', input_autogrow);
    TomSelect.define('remove_button', remove_button);
    this.tom = new TomSelect('#story_tags', {
      plugins: ['caret_position', 'input_autogrow', 'remove_button'],
      maxOptions: 200,
      maxItems: 10,
      hideSelected: true,
      closeAfterSelect: true,
      selectOnTab: true,
      sortField: {field: "data-value"},
      onInitialize: function() {
        const parent = qS('.ts-control');
        parent.appendChild(qS('.ts-dropdown'));
      },
      render: {
        option: function(data) {
          return '<div>' +
            '<span class="dropDownItem">' + data.title + '</span>' +
            '</div>';
        },
        item: function(data) {
          return '<a class="data-ts-item ' + data.tagCss + '">' + data.value + '</div>';
        }
      }
    });
  }

  upvoteComment(voterEl) {
    Lobster.voteComment(voterEl, 1);
  }

  upvoteStory(voterEl) {
    Lobster.voteStory(voterEl, 1);
  }

  voteStory(voterEl, point, reason) {
    if (!Lobster.curUser) return Lobster.bounceToLogin();

    const li = parentSelector(voterEl, '.story');
    const scoreDiv = qS(li, 'div.score');
    const formData = new FormData();
    formData.append('reason', reason || '');
    let showScore = true;
    let score = parseInt(scoreDiv.innerHTML);
    let action = "";

    if (isNaN(score)) {
      showScore = false;
      score = 0;
    }

    if (li.classList.contains("upvoted") && point > 0) {
      /* already upvoted, neutralize */
      li.classList.remove("upvoted");
      score--;
      action = "unvote";
    } else if (li.classList.contains("flagged") && point < 0) {
      /* already flagged, neutralize */
      li.classList.remove("flagged");
      score++;
      action = "unvote";
    } else if (point > 0) {
      if (li.classList.contains("flagged")) {
        /* Give back the lost flagged point */
        score++;
      }
      li.classList.remove("flagged");
      li.classList.add("upvoted");
      score++;
      action = "upvote";
    } else if (point < 0) {
      if (li.classList.contains("upvoted")) {
        /* Removes the upvote point this user already gave the story*/
        score--;
      }
      li.classList.remove("upvoted");
      li.classList.add("flagged");
      if (qS(li.parentElement, '.comment_folder_button')) {
        qS(li.parentElement, '.comment_folder_button').setAttribute('checked', true);
      };
      showScore = false;
      score--;
      action = "flag";
    }
    if (showScore) {
      scoreDiv.innerHTML = score;
    } else {
      scoreDiv.innerHTML = '~';
    }
    if (action == "upvote" || action == "unvote") {
      if (qS(li, '.reason')) {
        qS(li, '.reason').innerHTML = '';
      };

      if (action == "unvote" && point < 0)
        qS(li, '.flagger').textContent = 'flag';
      } else if (action == "flag") {
        qS(li, '.flagger').textContent = 'unflag';
    }

    fetchWithCSRF("/stories/" + li.getAttribute("data-shortid") + "/" + action, {
      method: 'post',
      body: formData });
  }

  voteComment(voterEl, point, reason) {
    if (!Lobster.curUser) return Lobster.bounceToLogin();

    const li = parentSelector(voterEl, ".comment");
    const scoreDiv = qS(li, 'div.score');
    const formData = new FormData();
    formData.append('reason', reason || '');
    let showScore = true;
    let score = parseInt(scoreDiv.innerHTML);
    let action = "";

    if (isNaN(score)) {
      showScore = false;
      score = 0;
    }

    if (li.classList.contains("upvoted") && point > 0) {
      /* already upvoted, neutralize */
      li.classList.remove("upvoted");
      score--;
      action = "unvote";
    } else if (li.classList.contains("flagged") && point < 0) {
      /* already flagged, neutralize */
      li.classList.remove("flagged");
      score++;
      action = "unvote";
    } else if (point > 0) {
      if (li.classList.contains("flagged")) {
        /* Give back the lost flagged point */
        score++;
      }
      li.classList.remove("flagged");
      li.classList.add("upvoted");
      score++;
      action = "upvote";
    } else if (point < 0) {
      if (li.classList.contains("upvoted")) {
        /* Removes the upvote point this user already gave the story*/
        score--;
      }
      li.classList.remove("upvoted");
      li.classList.add("flagged");
      li.parentElement.querySelector('.comment_folder_button').setAttribute("checked", true);
      showScore = false;
      score--;
      action = "flag";
    }
    if (showScore) {
      scoreDiv.innerHTML = score;
    } else {
      scoreDiv.innerHTML = '~';
    }

    if (action == "upvote" || action == "unvote") {
      qS(li, '.reason').innerHTML = '';
    }

    if (action == "unvote" && point < 0) {
      qS(li, '.flagger').textContent = 'flag';
    } else if (action == "flag") {
      qS(li, '.flagger').textContent = 'unflag';
      qS(li, '.reason').innerHTML = "| " + Lobster.commentFlagReasons[reason].toLowerCase();
    }

    fetchWithCSRF("/comments/" + li.getAttribute("data-shortid") + "/" + action, {
      method: 'post',
      body: formData });
  }
}

const Lobster = new _LobstersFunction();

onPageLoad(() => {
  Lobster.curUser = document.body.getAttribute('data-username'); // hack
  autosize(qSA('textarea'));

  // replace csrf token in forms that may be fragment caches with page token
  for (const i of qSA('form input[name="authenticity_token"]')) {
    i.value = csrfToken();
  }

  // Global

  on('click', '.markdown_help_label', (event) => {
    qS(parentSelector(event.target, '.markdown_help_toggler'), '.markdown_help').classList.toggle('display-block');
  });

  on('click', '#modal_backdrop', () => {
    Lobster.removeFlagModal()
  });

  on('click', '[data-confirm]', (event) => {
    if (!confirm(event.target.dataset.confirm)) {
      event.preventDefault();
    }
  });

  // Account Settings

  on('focusout', '#user_homepage', (event) => {
    const homePage = event.target
    if (homePage.value.trim() !== '' && !homePage.value.match('^[a-z]+:\/\/'))
      homePage.value = 'https://' + homePage.value
  });

  // Inbox

  on('change', '#message_hat_id', (event) => {
    let selectedOption = event.target.selectedOptions[0];
    qS('#message_mod_note').checked = (selectedOption.getAttribute('data-modnote') === 'true');
  });

  // Story

  Lobster.checkStoryTitle()

  Lobster.tomSelect();

  if (qS('#story_url') && qS('#story_preview') && !qS('#story_preview').firstElementChild) {
    qS('#story_url').focus()
  }

  on('change', '#story_title', Lobster.checkStoryTitle);

  on('click', '.story #flag_dropdown a', (event) => {
    event.preventDefault();
    if (event.target.getAttribute('data') != '') {
      Lobster.voteStory(parentSelector(event.target, '.story'), -1,  event.target.getAttribute('data'));
    }
    Lobster.removeFlagModal();
  });

  on('click', '#story_fetch_title', (event) => {
    Lobster.fetchURLTitle(event.target);
  });

  on('click', 'li.story a.upvoter', (event) => {
    event.preventDefault();
    Lobster.upvoteStory(event.target);
  });

  on('click', 'li.story a.flagger', (event) => {
    event.preventDefault();
    const reasons = Lobster.storyFlagReasons;
    Lobster.modalFlaggingDropDown("story", event.target, reasons);
  });

  on('click', 'li.story a.hider', (event) => {
    event.preventDefault();
    Lobster.hideStory(event.target);
  });

  on('click', 'li.story a.saver', (event) => {
    event.preventDefault();
    Lobster.saveStory(event.target);
  });

  on('click', 'button.story-preview', (event) => {
    Lobster.previewStory(parentSelector(event.target, 'form'));
  });

  on('focusout', '#story_url', () => {
    let url_tags = {
      "\.pdf$": "pdf",
      "[\/\.](asciinema\.org|(youtube|vimeo)\.com|youtu\.be|twitch.tv)\/": "video",
      "[\/\.](slideshare\.net|speakerdeck\.com)\/": "slides",
      "[\/\.](soundcloud\.com)\/": "audio",
    };

    const storyUrlEl = qS('#story_url');
    for (const [match, tag] of Object.entries(url_tags)) {
      if (storyUrlEl.value.match(new RegExp(match, "i"))) {
        Lobster.tom.addItem(tag.toLowerCase());
      }
    }

    // check for dupe if there's a URL, but not when editing existing
    if (storyUrlEl.value !== "" &&
      (!qS('input[name="_method"]') ||
      qS('input[name="_method"]').getAttribute('value') === 'put')) {
        Lobster.checkStoryDuplicate(parentSelector(storyUrlEl, 'form'));
    }
  });

  // Disown

  on('submit', 'form.disowner-form', (event) => {
    event.preventDefault();

    let type = event.target.elements['type'].value;

    if (confirm(`Are you sure you want to disown this ${type}?`)) {
      let li = parentSelector(event.target, `.${type}`);

      fetchWithCSRF(event.target.action, { method: 'post', body: new FormData(event.target) })
        .then(response => {
          response.text().then(text => replace(li, text));
        });
    }
  });

  // Comment

  // Remember story collapses; this is stored in localStorage for every story ID as an object
  on('change', '.comment_folder_button', (e) => {
    const commentId = e.target.getAttribute('data-shortid');
    const storyId = qS('.story')?.getAttribute('data-shortid');
    if (!storyId) return; // only remember or read these on story pages

    var collapse = JSON.parse(localStorage.getItem("collapse_" + storyId) || '{}');
    if (e.target.checked) {
      collapse[commentId] = 1; // value unused, just truthy and short to serialize
    } else {
      delete collapse[commentId];
    }
    localStorage.setItem("collapse_" + storyId, JSON.stringify(collapse));
  });

  // Collapse stories on load; the actual hiding is done in CSS; just need to switch the checkbox
  (function() {
    const storyId  = qS('.story')?.getAttribute('data-shortid');
    if (!storyId) return; // only remember or read these on story pages
    const collapse = JSON.parse(localStorage.getItem("collapse_" + storyId) || '{}');

    for (var k in collapse) {
      var folder = qS('input#comment_folder_' + k);
      // comment may have been deleted
      if (folder)
        folder.checked = true;
    }
  })();

  on("click", "a.comment_replier", (event) => {
    event.preventDefault();
    if (!Lobster.curUser) return Lobster.bounceToLogin();

    const comment = parentSelector(event.target, '.comment');
    const commentId = comment.getAttribute('id');

    // guard: don't create multiple reply boxes to one comment
    if (qS('#reply_form_' + commentId)) { return false; }

    // Inserts "> " on quoted text
    let sel = document.getSelection().toString();
    if (sel != "") {
      sel = sel.split("\n").map(s => "> " + s + '\n\n').join('');
      sel += "\n";
    }

    let div = document.createElement('div');
    div.innerHTML = '';
    comment.lastElementChild.append(div);

    fetchWithCSRF('/comments/' + comment.getAttribute('data-shortid') + '/reply')
      .then(response => {
        response.text().then(text => {
          // guard: don't create multiple reply boxes to one comment
          if (qS('#reply_form_' + commentId)) { return false; }

          div.innerHTML = text;
          div.setAttribute('id', 'reply_form_' + commentId);

          var ta = qS(div, 'textarea');
          ta.textContent = sel;
          // place the cursor at the end of the quoted string
          ta.setSelectionRange(sel.length, sel.length);
          ta.focus();
          autosize(ta);
        })
      });
  });

  on('click', '.comment a.flagger', (event) => {
    event.preventDefault();
    const reasons = Lobster.commentFlagReasons
    Lobster.modalFlaggingDropDown("comment", event.target, reasons);
  });

  on('click', '.comment #flag_dropdown a', (event) => {
    event.preventDefault();
    if (event.target.getAttribute('data') != '') {
      Lobster.voteComment(parentSelector(event.target, '.comment'), -1,  event.target.getAttribute('data'));
    }
    Lobster.removeFlagModal()
  });

  on("click", '.comment a.upvoter', (event) => {
    event.preventDefault();
    Lobster.upvoteComment(event.target);
  });

  on('click', 'button.comment-preview', (event) => {
    Lobster.previewComment(parentSelector(event.target, 'form'));
  });

  on('submit', '.comment_form_container form', (event) => {
    event.preventDefault();
    Lobster.postComment(event.target);
  });

  on('keydown', 'textarea#comment', (event) => {
    if ((event.metaKey || event.ctrlKey) && event.keyCode == 13) {
      Lobster.postComment(parentSelector(event.target, 'form'));
    }
  });

  on('click', 'button.comment-cancel', (event) => {
    const comment = (parentSelector(event.target, '.comment'));
    const commentId = comment.getAttribute('data-shortid');
    if (commentId !== null && commentId !== '') {
      fetch('/comments/' + commentId + '?show_tree_lines=true')
        .then(response => {
          response.text().then(text => replace(comment, text));
        });
    } else {
      comment.parentElement.remove();
    }
  });

  on('click', 'a.comment_editor', (event) => {
    let comment = parentSelector(event.target, '.comment');
    const commentId = comment.getAttribute('data-shortid')
    fetch('/comments/' + commentId + '/edit')
      .then(response => {
        response.text().then(text => {
          replace(comment, text);
          autosize(qSA('textarea'));
        });
      });
    autosize(qSA('textarea'));
  });

  on("click", "a.comment_deletor", (event) => {
    event.preventDefault();
    if (confirm("Are you sure you want to delete this comment?")) {
      const comment = parentSelector(event.target, '.comment');
      const commentId = comment.getAttribute('data-shortid');
      fetchWithCSRF('/comments/' + commentId + '/delete',{method: 'post'})
        .then(response => {
          response.text().then(text => replace(comment, text));
        });
    }
  });

  on('click', 'a.comment_undeletor', (event) => {
    event.preventDefault();
    if (confirm("Are you sure you want to undelete this comment?")) {
      const comment = parentSelector(event.target, '.comment');
      const commentId = comment.getAttribute('data-shortid');
      fetchWithCSRF('/comments/' + commentId + '/undelete', {method: 'post'})
        .then(response => {
          response.text().then(text => replace(comment, text));
        });
    }
  });

  on('click', 'a.comment_moderator', (event) => {
    const reason = prompt("Moderation reason:");
    if (reason == null || reason == '')
      return false;

    const formData = new FormData();
    formData.append('reason', reason);
    const comment = parentSelector(event.target, '.comment');
    const commentId = comment.getAttribute('data-shortid');
    fetchWithCSRF('/comments/' + commentId + '/delete', { method: 'post', body: formData })
      .then(response => {
        response.text().then(text => replace(comment, text));
      });
  });

  on('click', '.comment_unread', (event) => {
    const nodes = qSA('.comment_unread')
    const foundIndex = Array.from(nodes).findIndex(node => node === event.target)
    const targetIndex = (foundIndex + 1) % nodes.length;
    const targetY = nodes[targetIndex].getBoundingClientRect().top + window.scrollY
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    window.scrollTo({ top: targetY, behavior: reducedMotion ? 'instant' : 'smooth' })
  });

  // Private messages

  // inject js-only UI
  const select_all = qSA('.with_select_all tr:first-child th:first-child');
  for (const th of select_all) {
    const checkbox = document.createElement('input');
    checkbox.setAttribute('type', 'checkbox');
    checkbox.classList.add('select_all');
    th.append(checkbox);
  }

  on('click', '.select_all', (event) => {
    const table = parentSelector(event.target, 'table');
    const checkboxes = qSA(table, 'input[type=checkbox]');
    for (const checkbox of checkboxes) {
      checkbox.checked = event.target.checked;
    }
  });
});
