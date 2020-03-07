---
layout: page
title: About
permalink: /about/
---

  <h4>Category</h4>
  <ul>
      {% for category in site.categories %}
      <li><a href="/category/{{ category | first }}" title="view all
  posts">{{ category | first }} {{ category | last | size }}</a>
      </li>
      {% endfor %}
  </ul>