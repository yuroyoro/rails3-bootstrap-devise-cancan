if Rails.env.development? || Rails.env.test?
  module ActionController
    class LogSubscriber < ActiveSupport::LogSubscriber
      def start_processing(event)
        payload = event.payload
        params  = payload[:params].except(*INTERNAL_PARAMS)
        format  = payload[:format]
        format  = format.to_s.upcase if format.is_a?(Symbol)

        info "Processing by #{payload[:controller]}##{payload[:action]} as #{format}"
        info "  Parameters: \n#{params.ai.lines.map{|_| "  #{_}"}.join()}\n" unless params.empty?
      end
    end
  end

  class ActiveRecord::LogSubscriber
    def sql(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload

      return if 'SCHEMA' == payload[:name]

      name  = '%s (%.1fms)' % [payload[:name], event.duration]
      sql   = payload[:sql].squeeze(' ')
      binds = nil

      unless (payload[:binds] || []).empty?
        binds = "  " + payload[:binds].map { |col,v|
          [col.name, v]
        }.inspect
      end

      if odd?
        name = color(name, CYAN, true)
        sql  = color(sql, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      f= %r{app/((models|controllers|view)/.+)$}.method(:match)
      call_from = caller.find(&f).try(&f).try(:[], 0)

      if sql =~ /(BEGIN|COMMIT)/
        debug "  #{name}  #{sql}#{binds} : from #{call_from}"
      else
        msgs = []
        msgs << name
        msgs << sql.pretty_format_sql.lines.map{|_| "    #{_}"}.join()
        msgs << "  binds : #{binds}"  if binds.present?
        msgs << "  from  : #{call_from}"
        msgs << ""
        debug msgs.join("\n")
      end
    end
  end
end
