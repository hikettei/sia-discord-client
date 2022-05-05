require "discordrb"
require 'net/http'
require 'uri'
require "json"
require "facter"
class SIA
    def initialize(token,prefix)
        @SIA = Discordrb::Commands::CommandBot.new(token: token,prefix: prefix)
        @BASE_WEBHOOK = "https://discordapp.com/api/webhooks/"
        @Commands = {
            "help" => "コマンドリストを表示します",
            "settalk" => "SIA自然雑談システムを、コマンドを送信したチャンネルで使えるかを設定します",
            "eval" => "開発者限定コマンドです、入力されたテキストをその場で評価します",
            "si" => "サーバーの情報を表示します",
            "si <name or id>" => "サーバーの情報を表示します",
            "ui" => "ユーザーの情報を表示します",
            "ui <name or id>" => "ユーザーの情報を表示します",
            "ci" => "Eventがあったチャンネルの情報を表示します",
            "share <channel_id>" => "画面共有のURLを生成します",
            "bi" => "Botの情報を表示します",
            "重要" => "データの保存はされません、今現在テスト中なのでSIAが再起動されたらすべてのデータが削除されます"
        }
        @baseurl = "sianet.xyz:3000"
        @TalkEnabled = [
            539804456259158016
        ]
        @Myas = {}
    end

    def servers
        @SIA.servers.size
    end

	#メッセージを返信するときはかならずこれを使う
	def reply (channel,author,msg)
		rep = nil
		begin
			rep = channel.send_message(msg)
		rescue
			author.pm "Sorry :joy: | メッセージを送信しようとしたのですが、エラーが発生したか権限がありませんでした！"
		end
		rep
    end

    def sia
        @SIA
    end


    def request (text,history)
        uri = URI.parse("http://#{@baseurl}/talkapi/v3")

        params = {
            "msg" => text,
            "history" => history.join(",")
        }

        ret = Net::HTTP.post_form(uri, params)
        parsed = JSON.parse(ret.body)
    
        if parsed.include? "respond"
            return parsed["respond"]
        else
            return parsed["Error"]
        end
    end

    def run
        @SIA.ready do |event|
            @SIA.game = "#{@SIA.prefix} help / sianet.xyz"
        end

        @SIA.command :help do |event|
            help = ""
            @Commands.each{|k,v|
                help += "#{k} -> #{v} \n"
            }
            reply(event.channel,event.user,"```#{help}```")
            nil
        end

        @SIA.message do |event|
            if @TalkEnabled.include? event.channel.id
                unless event.message.content.start_with?(@SIA.prefix)
                    unless event.message.from_bot?
                        unless event.user.webhook?
                            event.channel.start_typing
                            historys = [""]
                            begin
                                event.channel.history(5).each{|msg|
                                    historys << msg.content
                                }
                            rescue

                            end
                            #    def send_webooks(author,message,channel)
                            # reply event.channel,event.user,(request event.message.content,historys)
                            sia_reply = request event.message.content,historys
                         #  sended = false
                         #   if @Myas.include?(event.user.id)
                         #       if @Myas[event.user.id][2]
                         #           send_webooks(@Myas[event.user.id][1],@Myas[event.user.id][0],sia_reply,event.channel)
                         #           sended = true
                         #       end
                         #   end

                         #   if sended
                            reply event.channel,event.user,sia_reply
                         #   end
                        end
                    end
                end
            end
            nil
        end

        @SIA.command :settalk do |event|
            if @TalkEnabled.include? event.channel.id
                @TalkEnabled.delete(event.channel.id)
                reply event.channel,event.user,"対話システムを無効にしました"
            else
                @TalkEnabled << event.channel.id
                reply event.channel,event.user,"対話システムを有効にしました"
            end
            nil
        end

        @SIA.command :ci do |event|
            reply(event.channel,event.user,"準備中")
            nil
        end

        @SIA.command :ui do |event,name|
            reply(event.channel,event.user,"準備中")
            nil
        end

        @SIA.command :myas do |event,name,url|
            if name == "set"
                if @Myas.include?(event.user.id)
                    url = (url == "on" ? true:false)
                    @Myas[event.user.id][2] = url
                    reply(event.channel,event.user,"設定しました")
                else
                    reply(event.channel,event.user,"データベースが見つかりません。")
                end
            else
                @Myas[event.user.id] = [name,url,true]
                reply(event.channel,event.user,"設定されました、`sia settalk`コマンドで試してみましょう")
            end
        end

        @SIA.command :bi do |event,name|
            reply(event.channel,event.user,(
                ["```yml",
                "GuildCount: #{@SIA.servers.size}",
                "MemberCount: #{@SIA.users.size}",
                "OfficialServer: https://discord.gg/cc372St",
                "InviteLink: https://discordapp.com/oauth2/authorize?client_id=456001323561648129&scope=bot&permissions=401993207",
                "API BaseURL: #{@baseurl}",
                "OfficialPage: sianet.xyz:7000",
                "Kernel:**#{Facter.value(:kernel)}**",
                "OS:**#{Facter.value(:operatingsystem)}**",
                "RAM:**#{Facter.value(:memorysize)}**",
                "CPU:**#{Facter.value(:processor0)}**","SIA Talk System By Rulia(@_VegaXVll)```"].join("\n")
            ))
            nil
        end

        @SIA.command :si do |event,*names|
            name = names.join(" ")
            server = event.server
            if name != ""
                @SIA.servers.each{|k,v|
                    if v.name == name || v.id.to_s == name
                        server = v
                        break
                    end
                }
            end

            reply event.channel,event.user,(
                ["```yml",
                "\"===#{server.name}===\"",
                "Membercount: #{server.member_count}",
                "ChannelCount: #{server.channels.size}",
                "OwnerNane: #{server.owner.name}",
                "By sianet.xyz```"].join("\n")
            )
            nil
        end
        @SIA.command :set_baseurl do |event,url|
            if event.user.id == 350796206449885186
                @baseurl = url
                reply event.channel,event.user,"#{url}に変更しました"           
            else
                reply event.channel,event.user,"このコマンドは管理者のみ使用できます"
            end
        end
        
        @SIA.command :share do |event,id|
            begin
                if @SIA.channel(id).voice?
                    reply(event.channel,event.user,"https://canary.discordapp.com/channels/#{event.server.id}/#{id}")
                else
                    reply(event.channel,event.user,"ボイスチャンネルを指定してください")
                end
            rescue
                reply(event.channel,event.user,"チャンネルIDが正しくありませんよ...")
            end 
            nil
        end
        
        @SIA.command :eval do |event,*args|
            if event.user.id == 350796206449885186
                begin
                    result = eval args.join(" ")
                    reply event.channel,event.user,result
                rescue
                    reply event.channel,event.user,"Error | 正常に実行されませんでした"
                end
            end
        end

        @SIA.run
    end

    def contains_sia?(token, channel_id)
        result = Discordrb::API.request(
            :channels_cid_webhooks,
            channel_id,
            :get,
            "#{Discordrb::API.api_base}/channels/#{channel_id}/webhooks",
            Authorization: token
        )
        res = ""
        JSON.parse(result.to_s).each{|obj|
            res = obj['id'] + "/" + obj['token'] if obj["name"] == "SIA_Global"
        }
        res
    end

    def create_webhook(token, channel_id, name, avatar, reason = nil)
        result = Discordrb::API.request(
            :channels_cid_webhooks,
            channel_id,
            :post,
            "#{Discordrb::API.api_base}/channels/#{channel_id}/webhooks",
            { name: name, avatar: avatar }.to_json,
            Authorization: token,
            content_type: :json,
            'X-Audit-Log-Reason': reason
        )
        "https://discordapp.com/api/webhooks/" + channel_id + JSON.parse(result.to_s)['token']
    end

     def get_webhooks(channel_id)
        tex = contains_sia?(@Bot.token,channel_id)
        return "https://discordapp.com/api/webhooks/" + tex if tex != ""
        return create_webhook(@Bot.token,channel_id,"SIA_Global","https://cdn.discordapp.com/avatars/456001323561648129/ec7341d89601d6f0e4ce88ed0e1f541f.webp",nil)
    end

    def send_webooks(avatarurl,avatarname,message,channel)
        begin
            webhook_url = get_webhooks(channel.id)
            return false if webhook_url == ""
            client = Discordrb::Webhooks::Client.new(url: webhook_url)
            client.execute do |builder|
                builder.content = message.content
                builder.username = avatarname
                builder.avatar_url = avatarurl
            end
        rescue
            p "Error"
        end

        true
    end
end