# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.RichMedia.ParserTest do
  use Pleroma.DataCase, async: false

  alias Pleroma.Web.RichMedia.Parser
  alias Pleroma.Web.RichMedia.Parser.Embed

  import Tesla.Mock

  setup do
    mock_global(fn env -> apply(HttpRequestMock, :request, [env]) end)
  end

  test "returns empty embed when no metadata present" do
    expected = %Embed{
      meta: %{},
      oembed: nil,
      title: nil,
      url: "https://example.com/empty"
    }

    assert Parser.parse("https://example.com/empty") == {:ok, expected}
  end

  test "parses ogp" do
    url = "https://example.com/ogp"

    expected = %Embed{
      meta: %{
        "og:image" => "http://ia.media-imdb.com/images/rock.jpg",
        "og:title" => "The Rock",
        "og:description" =>
          "Directed by Michael Bay. With Sean Connery, Nicolas Cage, Ed Harris, John Spencer.",
        "og:type" => "video.movie",
        "og:url" => "http://www.imdb.com/title/tt0117500/"
      },
      oembed: nil,
      title: "The Rock (1996)",
      url: "https://example.com/ogp"
    }

    assert Parser.parse(url) == {:ok, expected}
  end

  test "gets <title> tag" do
    url = "https://example.com/ogp-missing-title"
    expected = "The Rock (1996)"
    assert {:ok, %Embed{title: ^expected}} = Parser.parse(url)
  end

  test "parses twitter card" do
    url = "https://example.com/twitter-card"

    expected = %Embed{
      meta: %{
        "twitter:card" => "summary",
        "twitter:description" => "View the album on Flickr.",
        "twitter:image" => "https://farm6.staticflickr.com/5510/14338202952_93595258ff_z.jpg",
        "twitter:site" => "@flickr",
        "twitter:title" => "Small Island Developing States Photo Submission"
      },
      oembed: nil,
      title: nil,
      url: "https://example.com/twitter-card"
    }

    assert Parser.parse(url) == {:ok, expected}
  end

  test "parses OEmbed" do
    url = "https://example.com/oembed"

    expected = %Embed{
      meta: %{},
      oembed: %{
        "author_name" => "\u202E\u202D\u202Cbees\u202C",
        "author_url" => "https://www.flickr.com/photos/bees/",
        "cache_age" => 3600,
        "flickr_type" => "photo",
        "height" => "768",
        "html" =>
          "<a href=\"https://www.flickr.com/photos/bees/2362225867/\" title=\"Bacon Lollys by \u202E\u202D\u202Cbees\u202C, on Flickr\"><img src=\"https://farm4.staticflickr.com/3040/2362225867_4a87ab8baf_b.jpg\" width=\"1024\" height=\"768\" alt=\"Bacon Lollys\"/></a>",
        "license" => "All Rights Reserved",
        "license_id" => 0,
        "provider_name" => "Flickr",
        "provider_url" => "https://www.flickr.com/",
        "thumbnail_height" => 150,
        "thumbnail_url" => "https://farm4.staticflickr.com/3040/2362225867_4a87ab8baf_q.jpg",
        "thumbnail_width" => 150,
        "title" => "Bacon Lollys",
        "type" => "photo",
        "url" => "https://farm4.staticflickr.com/3040/2362225867_4a87ab8baf_b.jpg",
        "version" => "1.0",
        "web_page" => "https://www.flickr.com/photos/bees/2362225867/",
        "web_page_short_url" => "https://flic.kr/p/4AK2sc",
        "width" => "1024"
      },
      url: "https://example.com/oembed"
    }

    assert Parser.parse(url) == {:ok, expected}
  end

  test "cleans corrupted meta data" do
    expected = %Embed{
      meta: %{
        "Keywords" => "Konsument i zakupy",
        "ROBOTS" => "NOARCHIVE",
        "fb:app_id" => "515714931781741",
        "fb:pages" => "288018984602680",
        "google-site-verification" => "3P4BE3hLw82QWqtseIE60qQcOtrpMxMnCNkcv62pjTA",
        "news_keywords" => "Konsument i zakupy",
        "og:image" =>
          "https://bi.im-g.pl/im/f7/49/17/z24418295FBW,Prace-nad-projektem-chusty-antysmogowej-rozpoczely.jpg",
        "og:locale" => "pl_PL",
        "og:site_name" => "wyborcza.biz",
        "og:type" => "article",
        "og:url" =>
          "http://wyborcza.biz/biznes/7,147743,24417936,pomysl-na-biznes-chusta-ktora-chroni-przed-smogiem.html",
        "twitter:card" => "summary_large_image",
        "twitter:image" =>
          "https://bi.im-g.pl/im/f7/49/17/z24418295FBW,Prace-nad-projektem-chusty-antysmogowej-rozpoczely.jpg",
        "viewport" => "width=device-width, user-scalable=yes"
      },
      oembed: nil,
      title: nil,
      url: "https://example.com/malformed"
    }

    assert Parser.parse("https://example.com/malformed") == {:ok, expected}
  end

  test "returns error if getting page was not successful" do
    assert {:error, :overload} = Parser.parse("https://example.com/error")
  end

  test "does a HEAD request to check if the body is too large" do
    assert {:error, :body_too_large} = Parser.parse("https://example.com/huge-page")
  end

  test "does a HEAD request to check if the body is html" do
    assert {:error, {:content_type, _}} = Parser.parse("https://example.com/pdf-file")
  end
end
