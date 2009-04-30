# Copyright (c) 2008 Lucas Carlson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class StandardFailure < StandardError; end
class StandardFailureError < StandardError; end

module StandardFailureMethods
  def error(failure_method, options={}, &block)
    failure_method = failure_method.to_s
    @____standard_failures ||= {}
    unique_methods = self.methods + self.private_methods + self.protected_methods - Object.methods - Object.private_methods

    if failure_method.nil?
      raise StandardFailureError, "error() must be passed a non-nil argument"
    elsif !unique_methods.include?(failure_method)
      raise StandardFailureError, "When calling error(:#{failure_method}) you must define a method #{failure_method} within the class that error(:#{failure_method}) is called to handle failures."
    end
    
    case options[:unless]
    when Array
      if options[:unless].any? { |condition| !unique_methods.include?(condition.to_s) || @____standard_failures[condition.to_s] == :failed }
        return true
      end
    when Symbol, String
      condition = options[:unless]
      if !unique_methods.include?(condition.to_s) || @____standard_failures[condition.to_s] == :failed
        return true
      end
    when false, nil
      # on with the tests
    else
      return true
    end
        
    if block.call
      @____standard_failures[failure_method] = :failed
      self.send(failure_method.to_sym)
      if new_failure_method = options[:retry]
        options[:retry] = nil
        return error(new_failure_method, options, &block)
      end
    else
      @____standard_failures[failure_method] = :passed
    end
    
    return @____standard_failures[failure_method]
  end
  
  def error!(failure_method, options={}, &block)
    if error(failure_method, options, &block) == :failed
      raise StandardFailure, "A standard #{failure_method.to_s.gsub("_", " ")} failure has occurred. You should suppress this error by wrapping your error() methods around a begin; rescue StandardFailure; end block. Details: #{@____standard_failures.inspect}"
    end
  end
  
  alias :e :error
  alias :e! :error!
end
