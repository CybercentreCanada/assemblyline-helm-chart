Assemblyline Helm
=================

This chart is a WIP. It should build a generic assemblyline instance suitable for 
use directly, or as a component in more complex deployment setups or charts.

assemblyline
------------

A chart that launches Assemblyline assuming the logging infrastructure is maintained 
externally.


assemblyline_logging
--------------------

Chart that launches the above chart, but with a separate elastic instance for 
logging and launches an APM server.