<gf-articles>
    <div class="row">
        <div class="col-xs-12">
            <div each={articles} class="suggestion list-group-item m-b-1">
                <div class="suggestion-image" onclick={preview}
                        style="background-image: url('{thumbnail}');">
                </div>
                <div class="suggestion-body" onclick={preview}>
                    <p class="suggestion-title"
                       data-toggle="popover" data-placement="top" data-trigger="hover" data-content={title}>{title}</p>
                    <p class="suggestion-text">{description}</p>
                </div>
                <div class="suggestion-footer">
                    <span class="suggestion-views text-muted">{$.i18n('article-pageviews', pageviews)}</span>
                </div>
            </div>
        </div>
    </div>

    <script>
        var self = this;

        self.articles = opts.articles || [];
        self.source = opts.source || 'no-source-language';
        self.target = opts.target || 'no-target-language';

        var thumbQuery = 'https://{source}.wikipedia.org/w/api.php?action=query&pithumbsize=512&format=json&prop=pageimages&titles=';

        self.detail = function (article) {
            return $.ajax({
                url: thumbQuery.replace('{source}', self.source) + article.title,
                dataType: 'jsonp',
                contentType: 'application/json'
            }).done(function (data) {
                var id = Object.keys(data.query.pages)[0],
                    page = data.query.pages[id];

                article.id = id;
                article.linkTitle = encodeURIComponent(article.title);
                article.title = page.title;
                article.thumbnail = page.thumbnail ? page.thumbnail.source : 'static/images/lines.svg';
                article.hovering = false;
                self.update();

            });
        };

        var descriptionQuery = 'https://wikidata.org/w/api.php?action=wbgetentities&format=json&sites={source}wiki&redirects=yes&props=descriptions&languages={source}&titles='

        String.prototype.replaceAll = function(search, replacement) {
            var target = this;
            return target.replace(new RegExp(search, 'g'), replacement);
        };

        self.get_description = function(article) {
            var url = descriptionQuery.replaceAll('{source}', self.source) + article.title
            return $.ajax({
                url: url,
                dataType: 'jsonp',
                contentType: 'application/json'
            }).done(function (data) {
                var id = Object.keys(data.entities)[0];
                var descriptions = data.entities[id].descriptions;
                if (Object.keys(descriptions).length == 0) {
                    return;
                }
                var lang = Object.keys(data.entities[id].descriptions)[0];
                article.description = data.entities[id].descriptions[lang].value;
                self.update();

            });
        };

        preview (e) {
            riot.mount('gf-preview', {
                articles: self.articles,
                title: e.item.title,
                from: self.source,
                to: self.target
            });
        }

        hoverIn (e) {
            e.item.hovering = true;
        }

        hoverOut (e) {
            e.item.hovering = false;
        }

        // kick off the loading of the articles
        var promises = self.articles.map(self.detail).concat(self.articles.map(self.get_description));
        $.when.apply(this, promises).then(self.refresh);

        self.on('update', function () {
            // add tooltips for truncated article names
            $.each($('.suggestion-title'), function (index, item) {
                if ($(item.scrollWidth)[0] > $(item.offsetWidth)[0]) {
                    $(item).popover({
                        template: '<div class="popover" role="tooltip"><div class="popover-arrow"></div><div class="popover-content"></div></div>'
                    });
                } else {
                    $(item).popover('dispose');
                }
            });
        });
    </script>

</gf-articles>
