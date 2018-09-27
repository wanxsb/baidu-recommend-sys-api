module Baidu
  class BceRecommendMetaApi < BceRecommendBaseApi
    HOST = 'recrcv.bj.baidubce.com'
    base_uri  "https://#{HOST}"
    HTTP_METHOD = :post

    def get_http_method
      HTTP_METHOD
    end

    def get_host
      HOST
    end

    # {             
    #  "i": // id，新闻ID
    #  "c": // channel，所属频道，与产品内部分类对应；例如："社会"，"财经"，"军事"，"科技"
    #  "l": // label，新闻主题标签，例如：["搞笑","校园","美女"]
    #  "kw": // keyword，新闻关键词，例如：["安东尼","转会","火箭"]
    #  "ty": //type, 新闻类型，例如："文字"，"图文"，"图集"，"视频"，"投票"
    #  "ti": // title，新闻标题
    #  "al"://author list 作者
    #  "con": // content，新闻正文内容
    #  "src": // source，新闻来源，例如："新华社"、"凤凰网"
    #  "pid": // publisher id，新闻发布者，订阅号ID
    #  "pt": // publish time，发布时间,unix时间戳，毫秒
    #  "lang": // lang，语言，"en","zh"
    #  "op": "add" // 本条记录的操作类型，默认add。除了值为'del'表示删除，其他全部按add逻辑处理
    # }
    def itemmeta(base_article, op = 'add')
      send_request("/v1/rcv/itemmeta", {}, base_article.meta_data.merge({op: op}))
      base_article.mark_brs_synchronized
    end

    def useraction(meta_data)
      send_request("/v1/rcv/useraction", {}, meta_data)
    end

    def usermeta(base_user, op = 'add')
      send_request("/v1/rcv/usermeta", {}, base_user.meta_data.merge({op: op}))
    end

  end
end