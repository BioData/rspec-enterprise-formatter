require 'rspec/core/formatters/base_text_formatter'

PREFIX = "spec"

class FileOutput
    
    def initialize(file_name)
        @f = File.open(file_name, "w")
    end
    
    def puts(text)
        @f.puts(text)
    end
    
    def flush()
        @f.flush()
    end

end

class SplithtmlFormatter < RSpec::Core::Formatters::BaseTextFormatter

    def initialize(output)
        super(output)
        @example_group_number = 0
        @example_number = 0
        @failure_number = 0
        @pending_number = 0
        @header_red = nil
        @run_time = 0.0
        @test_file_name = ""
        @start_time = 0.0
        @end_time = 0.0
    end

private

    def method_missing(m, *a, &b)
    end
    
    def new_html(description)
        debug_print("description:" + description)
        basename = "#{description.gsub(/[^a-zA-Z0-9]+/, '-')}"
        max_filename_size = (ENV['MAX_FILENAME_SIZE'] || 2**8).to_i
        basename = basename[0..max_filename_size] if basename.length > max_filename_size
        debug_print("basename:" + basename)
        basedir = ENV['HTML_REPORTS'] || File.expand_path("#{Dir.getwd}/#{PREFIX.downcase}/reports")
        debug_print("basedir:" + basedir)
        FileUtils.mkdir_p(basedir)
        full_path = "#{basedir}/#{PREFIX.upcase}-#{basename}" 
        debug_print("full_path:" + full_path)  
        suffix = "html"
        filename = [full_path, suffix].join(".")
        i = 0
        while File.exists?(filename) && i < 2**15
            filename = [full_path, i, suffix].join(".")
            i += 1
        end
        debug_print("filename:" + filename)
        file_out_put = FileOutput.new(filename)
        return SplitHtmlPrinter.new(file_out_put)
    end

public

    def message(message)
    end

    def start(example_count)
        super(example_count)
    end

    def example_group_started(example_group)
        super(example_group)
        @start_time = Time.now().to_f()
        @example_number = 0
        @failure_number = 0
        @pending_number = 0
        @header_red = false
        @run_time = 0.0
        @example_group_red = false
        @example_group_number += 1
        test_file_name = File.basename(example_group.metadata[:example_group][:file_path])
        @printer = new_html(example_group.description.to_s)
        @printer.print_html_start(test_file_name)
        @printer.print_example_group_start(example_group.description)
        @printer.flush()
        debug_print("start:" + @printer.object_id.to_s)
    end
    
    def example_group_finished(example_group)
        super(example_group)
        @printer.print_example_group_end()
        test_file_path = File.expand_path(example_group.metadata[:example_group][:file_path])
        @end_time = Time.now().to_f()
        @printer.print_summary(false, @run_time, @example_number, @failure_number, @pending_number, test_file_path, @start_time, @end_time)
        @printer.flush()
        debug_print("finished:" + @printer.object_id.to_s)
    end

    def example_started(example)
        super(example)
        @example_number += 1
        @printer.print_example_start()
    end

    def example_passed(example)
        @printer.move_progress(100)
        @printer.print_example_passed( example.description, example.execution_result[:run_time] )
        @printer.flush()
        @run_time += example.execution_result[:run_time]
    end
    
    def example_failed(example)
        super(example)

        unless @header_red
            @header_red = true
            @printer.make_header_red
        end

        unless @example_group_red
            @example_group_red = true
            @printer.make_example_group_header_red(0)
        end

        @printer.move_progress(100)

        exception = example.metadata[:execution_result][:exception]
        exception_details = if exception
        {
          :message => exception.message,
          :backtrace => format_backtrace(exception.backtrace, example).join("\n")
        }
        else
            false
        end
        
        extra = extra_failure_content(exception)

        @printer.print_example_failed(
            example.execution_result[:pending_fixed],
            example.description,
            example.execution_result[:run_time],
            @failed_examples.size,
            exception_details,
            (extra == "") ? false : extra,
            true
        )

        @printer.flush()
        @failure_number += 1
        @run_time += example.execution_result[:run_time]
    end
    
    def example_pending(example)
        @printer.make_header_yellow unless @header_red
        @printer.make_example_group_header_yellow(example_group_number) unless @example_group_red
        @printer.move_progress(100)
        @printer.print_example_pending( example.description, example.metadata[:execution_result][:pending_message] )
        @printer.flush()
        @pending_number += 1
        @run_time += example.execution_result[:run_time]
    end
    
    def example_step_started(example, type, message, options)
        example_started(example)
    end
    
    def example_step_passed(example, type, message, options)
        @printer.move_progress(100)
        @printer.print_example_passed( type.to_s().upcase() + ' ' + message, 0 )
        @printer.flush()
    end

    def example_step_failed(example, type, message, options)
        
        unless @header_red
            @header_red = true
            @printer.make_header_red
        end

        unless @example_group_red
            @example_group_red = true
            @printer.make_example_group_header_red(0)
        end

        @printer.move_progress(100)

        exception = example.metadata[:execution_result][:exception]
        exception_details = if exception
        {
          :message => exception.message,
          :backtrace => format_backtrace(exception.backtrace, example).join("\n")
        }
        else
            false
        end

        @printer.print_example_failed(
            example.execution_result[:pending_fixed],
            type.to_s().upcase() + ' ' + message,
            0,
            @failed_examples.size,
            exception_details,
            false,
            true
        )

        @printer.flush()
        @failure_number += 1
    end

    def example_step_pending(example, type, message, options)
        @printer.make_header_yellow unless @header_red
        @printer.make_example_group_header_yellow(example_group_number) unless @example_group_red
        @printer.move_progress(100)
        @printer.print_example_pending( type.to_s().upcase() + ' ' + message, '')
        @printer.flush()
        @pending_number += 1
    end
   
    def extra_failure_content(exception)
        require 'rspec/core/formatters/snippet_extractor'
        backtrace = exception.backtrace.map {|line| backtrace_line(line)}
        backtrace.compact!
        @snippet_extractor ||= RSpec::Core::Formatters::SnippetExtractor.new
        "    <pre class=\"ruby\"><code>#{@snippet_extractor.snippet(backtrace)}</code></pre>"
    end

    def start_dump
    end
    
    def dump_failures
    end

    def dump_pending
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
    end
    
end
