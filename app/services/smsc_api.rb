require "net/http"
require "net/https"
require "net/smtp"
require "uri"
require "erb"

class SMSC
	def initialize(login, password)
		@login = login
		@password = password
	end

	SMSC_POST = false				 
	SMSC_HTTPS = false				 
	SMSC_CHARSET = "utf-8"			 
	SMSC_DEBUG = false			 
	SMTP_FROM = "api@smsc.ru"		 

	def send_sms(phones, message, translit = 0, time = 0, id = 0, format = 0, sender = false, query = "")

		m = _smsc_send_cmd("send", "phones=" + _urlencode(phones) + "&mes=" + _urlencode(message) +
			"&translit=#{translit}&id=#{id}" + (sender == false ? "" : "&sender=" + _urlencode(sender)))
	end

	def get_status(id, phone, all = 0)
		m = _smsc_send_cmd("status", "phone=" + _urlencode(phone) + "&id=#{id}&all=#{all}")
		if SMSC_DEBUG
			if m[1] != "" && m[1] >= "0"
				puts "Статус SMS = #{m[0]}" + (m[1] > "0" ? ", время изменения статуса - " + Time.at(m[1].to_i).strftime("%d.%m.%Y %T") : "") + "\n"
			else
				puts "Ошибка №#{m[1][1]}\n"
			end
		end

		if all && m.size > 9 && ((defined?(m[14])).nil? || m[14] != "HLR")
			m = (m.join(",")).split(",", 9)
		end
	end

	# ВНУТРЕННИЕ ФУНКЦИИ
	# Функция вызова запроса. Формирует URL и делает 5 попыток чтения

	def _smsc_send_cmd(cmd, arg = "")
		url_orig = (SMSC_HTTPS ? "https" : "http") + "://smsc.ru/sys/#{cmd}" + ".php?login=" + _urlencode(@login) + "&psw=" + _urlencode(@password) + "&fmt=1&charset=#{SMSC_CHARSET}&#{arg}"
		url = url_orig.clone
		uri = URI.parse(url)
		http = _server_connect(uri)

		i = 1
		begin

			if (i > 1)
				url = url_orig.clone
				url.sub!("://smsc.ru/", "://www" + i.to_s + ".smsc.ru/")
				uri = URI.parse(url)
				http = _server_connect(uri)
			end

			begin
				r = (SMSC_POST || url.length > 2000) ? http.post2(uri.path, uri.query) : http.get2(uri.path + "?" + uri.query)
				ret = r.body
			rescue
				ret = ""
			end

			i+=1
		end until ret != "" || i == 6

		if ret == ""
			puts "Ошибка чтения адреса: #{url}\n" if SMSC_DEBUG

			ret = "0,0" # фиктивный ответ
		end

		return ret.split(",")
	end

	# Подключение к серверу

	def _server_connect(uri)
		http = Net::HTTP.new(uri.host, uri.port)

		if SMSC_HTTPS
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end

		return http
	end
	
	# кодирование параметра в http-запросе

	def _urlencode(str)
		ERB::Util.url_encode(str)
	end
end
