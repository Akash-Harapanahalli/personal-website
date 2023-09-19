---
layout: archive
title: "Publications"
permalink: /publications/
author_profile: true
---
<i>\* indicates equal contribution</i>

{% if author.googlescholar %}
  You can also find my articles on <u><a href="{{author.googlescholar}}">my Google Scholar profile</a>.</u>
{% endif %}

{% include base_path %}

<!-- {% for post in site.publications reversed %}
  {% include archive-pub.html %}
{% endfor %} -->
<!-- <style>
  /* .laparent li { font-size: 20 } */
  /* .laparent ol { counter-reset: item } */
  /* .laparent li { display: block ; counter-increment: item; } */
    /* replace the counter before list item with
              open parenthesis + counter + close parenthesis */
  /* .laparent li:before { content: "[" counter(item) "] "; } */
</style> -->
<div>
  <ol class="laparent" reversed>{% for post in site.publications reversed %}
    {% include archive-pub.html %}
  {% endfor %}</ol>
</div>