{% extends "modules/modulefile.lua" %}
{% block footer %}
{% set incdir = spec.prefix + "/include" %}
if isDir("{{ incdir }}") then
    prepend_path("CPATH", "{{ incdir }}")
end
{% for lib in ["lib","lib64"] %}
{% set libdir = spec.prefix + "/" + lib %}
if isDir("{{ libdir }}") then
    prepend_path("LIBRARY_PATH", "{{ libdir }}")
    prepend_path("LD_LIBRARY_PATH", "{{ libdir }}")
end
{% endfor %}
{% endblock %}
