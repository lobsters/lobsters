//= require jquery
//= require jquery_ujs
//= require_tree .

"use strict";

var _Lobsters = Class.extend({
	commentDownvoteReasons: { "": "Cancel" },
	storyDownvoteReasons: { "": "Cancel" },

	upvote: function(story_id) {
		Lobsters.vote("story", story_id, 1);
	},
	downvote: function(story_id) {
		Lobsters._showDownvoteWhyAt("#story_downvoter_" + story_id,
			function(k) { Lobsters.vote('story', story_id, -1, k); });
	},

	upvoteComment: function(comment_id) {
		Lobsters.vote("comment", comment_id, 1);
	},
	downvoteComment: function(comment_id) {
		Lobsters._showDownvoteWhyAt("#comment_downvoter_" + comment_id,
			function(k) { Lobsters.vote('comment', comment_id, -1, k); });
	},

	_showDownvoteWhyAt: function(el, onChooseWhy) {
		if ($("#downvote_why"))
			$("#downvote_why").remove();

		var d = $("<div id=\"downvote_why\"></div>");

		var reasons;
		if ($(el).attr("id").match(/comment/))
			reasons = Lobsters.commentDownvoteReasons;
		else
			reasons = Lobsters.storyDownvoteReasons;

		$.each(reasons, function(k, v) {
			var a = $("<a href=\"#\">" + v + "</a>");

			a.click(function() {
				$('#downvote_why').remove();

				if (k != "")
					onChooseWhy(k);

				return false;
			});

			d.append(a);
		});

		$(el).after(d);

		d.position({
			my: "left top",
			at: "left bottom",
			offset: "-2 -2",
			of: $(el),
			collision: "none",
		});
	},

	vote: function(thing_type, thing_id, point, reason) {
		var li = $("#" + thing_type + "_" + thing_id);
		var score_d = li.find("div.score").get(0);
		var score = parseInt(score_d.innerHTML);
		var action = "";

		if (li.hasClass("upvoted") && point > 0) {
			/* already upvoted, neutralize */
			li.removeClass("upvoted");
			score--;
			action = "unvote";
		}
		else if (li.hasClass("downvoted") && point < 0) {
			/* already downvoted, neutralize */
			li.removeClass("downvoted");
			score++;
			action = "unvote";
		}
		else if (point > 0) {
			if (li.hasClass("downvoted"))
				/* flip flop */
				score++;

			li.removeClass("downvoted").addClass("upvoted");
			score++;
			action = "upvote";
		}
		else if (point < 0) {
			if (li.hasClass("upvoted"))
				/* flip flop */
				score--;

			li.removeClass("upvoted").addClass("downvoted");
			score--;
			action = "downvote";
		}

		score_d.innerHTML = score;

		$.post("/" + (thing_type == "story" ? "stories" :
			thing_type + "s") + "/" + thing_id + "/" + action,
			{ why: reason });
	},

	postComment: function(form) {
		$(form).load($(form).attr("action"), $(form).serializeArray());
	},

	previewComment: function(form) {
		$(form).load($(form).attr("action").replace(/^\/comments/,
			"/comments/preview"), $(form).serializeArray());
	},

	fetchURLTitle: function(button, url_field, title_field) {
		if (url_field.val() == "")
			return;

		var old_value = button.val();
		button.prop("disabled", true);
		button.val("Fetching...");

		$.post("/stories/fetch_url_title", {
			fetch_url: url_field.val(),
		})
		.success(function(data) {
			if (data && data.title)
				title_field.val(data.title.substr(0,
					title_field.maxLength));

			button.val(old_value);
			button.prop("disabled", false);
		})
		.error(function() {
			button.val(old_value);
			button.prop("disabled", false);
		});
	},
});

var Lobsters = new _Lobsters();

/* FIXME */
/* $(document).click(function() {
	$("#downvote_why").remove();
}); */
