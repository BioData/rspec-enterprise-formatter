require 'erb'
require 'delegate'
require 'stringio'

DEBUG = 0

def debug_print(msg)
    if DEBUG == 1
        STDOUT.puts "DEBUG:  " + msg
    end
end

class SplitHtmlPrinter

    include ERB::Util # for the #h method
    def initialize(output)
        @output = output
    end

public

    def print_html_start(test_file_name)
        @output.puts HTML_HEADER
        @output.puts "<div class=\"rspec-report\">"
        #@output.puts "<div id=\"rspec-header\">"
        #@output.puts " <div id=\"label\">"
        #@output.puts "   <h1>#{test_file_name}</h1>"
        #@output.puts " </div>"
        @output.puts REPORT_HEADER
    end

    def print_example_group_start(description)
        @output.puts "<div id=\"div_group_0\" class=\"example_group passed\">"
        @output.puts "  <dl #{indentation_style(1)}>"
        @output.puts "  <dt id=\"example_group_0\" class=\"passed\">#{h(description)}</dt>"

        @captured_io = StringIO.new()
        $stdout = @captured_io
        $stderr = @captured_io
    end

    def print_example_group_end()
        logs = @captured_io.string
        unless logs.empty?
          @output.puts "    <dd class=\"example passed\">"
          @output.puts "      <span class=\"\">after(:all)</span>"
          @output.puts "      <div class=\"console_log\">"
          @output.puts "        <pre>#{logs}</pre>"
          @output.puts "      </div>"
          @output.puts "    </dd>"
        end

        @output.puts "  </dl>"
        @output.puts "</div>"
    end

    def print_example_start()

    end

    def print_example_end()
        @captured_io.flush()
        @captured_io.string = @captured_io.string.gsub(/</, '&lt;')
        @captured_io.string = @captured_io.string.gsub(/>/, '&gt;')
        logs = @captured_io.string.dup
        @captured_io.truncate(0)
        @captured_io.seek(0)
        return logs
    end

    def header
      'style="background: gray;color: white;width: 200px;font-size: 16px;line-height: 18px;border:1px solid black"'
    end

    def content
      'style="width: 400px;font-size: 16px;line-height: 18px;border:1px solid black"'
    end

    def print_example_passed( description,notes, run_time )
      # @output.puts "    <dd class=\"example passed\">"
      # @output.puts "      <span class=\"passed_spec_name\">#{h(description)}</span>"
      # @output.puts "      <span class=\"duration\">#{formatted_run_time}s</span>"
      # @output.puts "      <div class=\"console_log\">"
      # @output.puts "        <pre>#{print_example_end()}</pre>"
      # @output.puts "      </div>"
      # @output.puts "    </dd>"

        formatted_run_time = sprintf("%.5f", run_time) if run_time
        @@spec_number ||= 0
        @@spec_number += 1
        @output.puts "<br/><table style='border-collapse:collapse; border:1px solid black'>"
        @output.puts "<tr>"
        @output.puts "<td #{header}> Requirement # </td>"
        @output.puts "<td #{content}> #{@@spec_number} </td>"
        @output.puts "</tr>"
        @output.puts "<tr>"
        @output.puts "<td #{header}> Description </td>"
        @output.puts "<td #{content}> #{h(description)} </td>"
        @output.puts "</tr>"
        @output.puts "<tr>"
        @output.puts "<td #{header}> Notes </td>"
        @output.puts "<td #{content}> #{notes}</td>"
        @output.puts "</tr>"
        @output.puts "</table>"
    end

    def print_example_failed( pending_fixed, description, run_time, failure_id, exception, extra_content, escape_backtrace = false )
        formatted_run_time = 0
        formatted_run_time = sprintf("%.5f", run_time) if run_time

        @output.puts "    <dd class=\"example #{pending_fixed ? 'pending_fixed' : 'failed'}\">"
        @output.puts "      <span class=\"failed_spec_name\">#{h(description)}</span>"
        @output.puts "      <span class=\"duration\">#{formatted_run_time}s</span>"

        @output.puts "      <div class=\"console_log\">"
        @output.puts "        <pre>#{print_example_end()}</pre>"
        @output.puts "      </div>"

        @output.puts "      <div class=\"failure\" id=\"failure_#{failure_id}\">"
        if exception
            @output.puts "        <div class=\"message\"><pre>#{h(exception[:message])}</pre></div>"
            if escape_backtrace
                @output.puts "        <div class=\"backtrace\"><pre>#{h exception[:backtrace]}</pre></div>"
            else
                @output.puts "        <div class=\"backtrace\"><pre>#{exception[:backtrace]}</pre></div>"
            end
        end
        @output.puts extra_content if extra_content
        @output.puts "      </div>"
        @output.puts "    </dd>"
    end

    def print_example_pending( description, pending_message )
        @output.puts "    <dd class=\"example not_implemented\">"
        @output.puts "      <span class=\"not_implemented_spec_name\">#{h(description)} (PENDING: #{h(pending_message)})</span>"
        @output.puts "      <div class=\"console_log\">"
        @output.puts "        <pre>#{print_example_end()}</pre>"
        @output.puts "      </div>"
        @output.puts "    </dd>"
    end

    def print_summary( was_dry_run, duration, example_count, failure_count, pending_count, test_path, start_time, end_time)
        totals =  "#{example_count} example#{'s' unless example_count == 1}, "
        totals << "#{failure_count} failure#{'s' unless failure_count == 1}"
        totals << ", #{pending_count} pending" if pending_count > 0
        formatted_duration = sprintf("%.5f", duration)
        @output.puts "<script type=\"text/javascript\">document.getElementById('duration').innerHTML = \"Finished in <strong>#{formatted_duration} seconds</strong>\";</script>"
        @output.puts "<script type=\"text/javascript\">document.getElementById('totals').innerHTML = \"#{totals}\";</script>"

        if failure_count != 0
            @output.puts "<p status=\"failed\"><span style=\"visibility:hidden\">#{failure_count}</span></p>"
        elsif pending_count != 0
            @output.puts "<p status=\"pending\"><span style=\"visibility:hidden\">#{pending_count}</span></p>"
        else
            @output.puts "<p status=\"passed\"><span style=\"visibility:hidden\">#{example_count}</span></p>"
        end
        @output.puts "<p test_file_path=#{test_path}><span style=\"visibility:hidden\"></span></p>"
        print_start_time(start_time)
        print_end_time(end_time)
        @output.puts "</div>"
        @output.puts "</div>"
        @output.puts "</body>"
        @output.puts "</html>"
    end

    def print_start_time(time)
        @output.puts "<p time=\"start_time\"><span style=\"visibility:hidden\">#{time}</span></p>"
    end

    def print_end_time(time)
        @output.puts "<p time=\"end_time\"><span style=\"visibility:hidden\">#{time}</span></p>"
    end

    def flush
        @output.flush
    end

    def move_progress( percent_done )
        @output.puts "    <script type=\"text/javascript\">moveProgressBar('#{percent_done}');</script>"
        @output.flush
    end

    def make_header_red
        @output.puts "    <script type=\"text/javascript\">makeRed('rspec-header');</script>"
    end

    def make_header_yellow
        @output.puts "    <script type=\"text/javascript\">makeYellow('rspec-header');</script>"
    end

    def make_example_group_header_red(group_id)
        @output.puts "    <script type=\"text/javascript\">makeRed('div_group_#{group_id}');</script>"
        @output.puts "    <script type=\"text/javascript\">makeRed('example_group_#{group_id}');</script>"
    end

    def make_example_group_header_yellow(group_id)
        @output.puts "    <script type=\"text/javascript\">makeYellow('div_group_#{group_id}');</script>"
        @output.puts "    <script type=\"text/javascript\">makeYellow('example_group_#{group_id}');</script>"
    end

private

    def indentation_style( number_of_parents )
        "style=\"margin-left: #{(number_of_parents - 1) * 15}px;\""
    end

    REPORT_HEADER = <<-EOF
  <div id="display-filters">
    <input id="passed_checkbox"  name="passed_checkbox"  type="checkbox" checked="checked" onchange="apply_filters()" value="1" /> <label for="passed_checkbox">Passed</label>
    <input id="failed_checkbox"  name="failed_checkbox"  type="checkbox" checked="checked" onchange="apply_filters()" value="2" /> <label for="failed_checkbox">Failed</label>
    <input id="pending_checkbox" name="pending_checkbox" type="checkbox" checked="checked" onchange="apply_filters()" value="3" /> <label for="pending_checkbox">Pending</label>
  </div>

  <div id="summary">
    <p id="totals">&#160;</p>
    <p id="duration">&#160;</p>
  </div>
</div>


<div class="results">
EOF

    GLOBAL_SCRIPTS = <<-EOF

function addClass(element_id, classname) {
  document.getElementById(element_id).className += (" " + classname);
}

function removeClass(element_id, classname) {
  var elem = document.getElementById(element_id);
  var classlist = elem.className.replace(classname,'');
  elem.className = classlist;
}

function moveProgressBar(percentDone) {
  document.getElementById("rspec-header").style.width = percentDone +"%";
}

function makeRed(element_id) {
  removeClass(element_id, 'passed');
  removeClass(element_id, 'not_implemented');
  addClass(element_id,'failed');
}

function makeYellow(element_id) {
  var elem = document.getElementById(element_id);
  if (elem.className.indexOf("failed") == -1) {  // class doesn't includes failed
    if (elem.className.indexOf("not_implemented") == -1) { // class doesn't include not_implemented
      removeClass(element_id, 'passed');
      addClass(element_id,'not_implemented');
    }
  }
}

function apply_filters() {
  var passed_filter = document.getElementById('passed_checkbox').checked;
  var failed_filter = document.getElementById('failed_checkbox').checked;
  var pending_filter = document.getElementById('pending_checkbox').checked;

  assign_display_style("example passed", passed_filter);
  assign_display_style("example failed", failed_filter);
  assign_display_style("example not_implemented", pending_filter);

}

function get_display_style(display_flag) {
  var style_mode = 'none';
  if (display_flag == true) {
    style_mode = 'block';
  }
  return style_mode;
}

function assign_display_style(classname, display_flag) {
  var style_mode = get_display_style(display_flag);
  var elems = document.getElementsByClassName(classname)
  for (var i=0; i<elems.length;i++) {
    elems[i].style.display = style_mode;
  }
}

EOF

GLOBAL_STYLES = <<-EOF
#rspec-header {
  background: #65C400; color: #fff; height: 4em;
}

.rspec-report h1 {
  margin: 0px 10px 0px 10px;
  padding: 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  font-size: 1.8em;
  position: absolute;
}

#label {
  float:left;
}

#display-filters {
  float:left;
  padding: 28px 0 0 40%;
  font-family: "Lucida Grande", Helvetica, sans-serif;
}

#summary {
  float:right;
  padding: 5px 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  text-align: right;
}

#summary p {
  margin: 0 0 0 2px;
}

#summary #totals {
  font-size: 1.2em;
}

.example_group {
  margin: 0 10px 5px;
  background: #fff;
}

dl {
  margin: 0; padding: 0 0 5px;
  font: normal 11px "Lucida Grande", Helvetica, sans-serif;
}

dt {
  padding: 3px;
  background: #65C400;
  color: #fff;
  font-weight: bold;
}

dd {
  margin: 5px 0 5px 5px;
  padding: 3px 3px 3px 18px;
  font-size: 12px;
}

dd .duration {
  padding-left: 5px;
  text-align: right;
  right: 0px;
  float:right;
}

dd .console_log {
  background-color:#000000;
  color: #FFFFFF;
  font-size: 9px;
}

dd.example.passed {
  border-left: 5px solid #65C400;
  border-bottom: 1px solid #65C400;
  background: #DBFFB4; color: #3D7700;
}

dd.example.not_implemented {
  border-left: 5px solid #FAF834;
  border-bottom: 1px solid #FAF834;
  background: #FCFB98; color: #131313;
}

dd.example.pending_fixed {
  border-left: 5px solid #0000C2;
  border-bottom: 1px solid #0000C2;
  color: #0000C2; background: #D3FBFF;
}

dd.example.failed {
  border-left: 5px solid #C20000;
  border-bottom: 1px solid #C20000;
  color: #C20000; background: #FFFBD3;
}


dt.not_implemented {
  color: #000000; background: #FAF834;
}

dt.pending_fixed {
  color: #FFFFFF; background: #C40D0D;
}

dt.failed {
  color: #FFFFFF; background: #C40D0D;
}


#rspec-header.not_implemented {
  color: #000000; background: #FAF834;
}

#rspec-header.pending_fixed {
  color: #FFFFFF; background: #C40D0D;
}

#rspec-header.failed {
  color: #FFFFFF; background: #C40D0D;
}


.backtrace {
  color: #000;
  font-size: 12px;
}

a {
  color: #BE5C00;
}

pre {
    white-space: pre-wrap;       /* css-3 */
    white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
    white-space: -pre-wrap;      /* Opera 4-6 */
    white-space: -o-pre-wrap;    /* Opera 7 */
    word-wrap: break-word;       /* Internet Explorer 5.5+ */
}

/* Ruby code, style similar to vibrant ink */
.ruby {
  font-size: 12px;
  font-family: monospace;
  color: white;
  background-color: black;
  padding: 0.1em 0 0.2em 0;
}

.ruby .keyword { color: #FF6600; }
.ruby .constant { color: #339999; }
.ruby .attribute { color: white; }
.ruby .global { color: white; }
.ruby .module { color: white; }
.ruby .class { color: white; }
.ruby .string { color: #66FF00; }
.ruby .ident { color: white; }
.ruby .method { color: #FFCC00; }
.ruby .number { color: white; }
.ruby .char { color: white; }
.ruby .comment { color: #9933CC; }
.ruby .symbol { color: white; }
.ruby .regex { color: #44B4CC; }
.ruby .punct { color: white; }
.ruby .escape { color: white; }
.ruby .interp { color: white; }
.ruby .expr { color: white; }

.ruby .offending { background-color: gray; }
.ruby .linenum {
  width: 75px;
  padding: 0.1em 1em 0.2em 0;
  color: #000000;
  background-color: #FFFBD3;
}
EOF

    HTML_HEADER = <<-EOF
<!DOCTYPE html>
<html lang='en'>
<head>
  <title>RSpec results</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Expires" content="-1" />
  <meta http-equiv="Pragma" content="no-cache" />
  <style type="text/css">
  body {
    margin: 0;
    padding: 0;
    background: #fff;
    font-size: 80%;
  }
  </style>
  <script type="text/javascript">
    // <![CDATA[
#{GLOBAL_SCRIPTS}
    // ]]>
  </script>
  <style type="text/css">
#{GLOBAL_STYLES}
  </style>
</head>
<body>
EOF

end
