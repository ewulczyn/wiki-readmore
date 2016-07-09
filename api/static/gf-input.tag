<gf-input>
    <form onsubmit={submitRequest}>
        <div class="container-fluid m-t-1">
            <div class="row m-b-1">
                <div class="col-xs-6 col-sm-4 col-md-3 col-lg-2 p-r-0">
                    <a type="button" class="btn btn-block btn-secondary source-selector" name="from">
                        <span class="selector-display">{$.i18n('selector-source')}</span>
                        <span class="icon icon-selector icon-expand"></span>
                    </a>
                </div>
            </div>
        </div>
        <div class="container-fluid seed-container" id="seed-container">
            <div class="row">
                <div class="col-xs-12">
                    <input type="text" autocomplete=off class="form-control seed-input"
                            placeholder="Search what to read next"
                            name="seedArticle">
                </div>
            </div>
        </div>
    </form>
    <div class="container-fluid m-t-1">
        <div class="row">
            <div class="col-xs-12 col-sm-8 col-md-6 col-lg-4">
                <div class="text-xs-center alert alert-info" data-i18n="status-preparing" if={fetching}>
                    {$.i18n('status-preparing')}
                </div>
                <div class="text-xs-center alert alert-danger" data-i18n="{error_msg}" if={error}>
                    {$.i18n(error_msg)}
                </div>
            </div>
        </div>
        <div class={invisible: fetching || error}>
            <gf-articles></gf-articles>
        </div>
    </div>

    <script>
        var self = this;

        self.source = '';
        self.sourceLanguages = {};
        self.fetching = false;
        self.sourceSelector = null;
        self.uls = [];
        self.origin = 'unknown';

        self.submitRequest = function () {
            self.origin = 'form_submit';
            self.fetchArticles();
            return false;
        };

        self.fetchArticles = function () {
            
            self.error = false;
            self.fetching = true;
            self.update();

            var url = '/api?s=' + self.source;

            var seed;
            if (this.seedArticle.value) {
                url += '&article=' + encodeURIComponent(this.seedArticle.value);
                seed = this.seedArticle.value;
            }


            $.ajax({
                url: url
            }).complete(function () {
                self.fetching = false;
                self.update();
            }).done(function (data) {
                if (data.error) {
                    self.error = true;
                    self.error_msg = data.error;
                    return;
                }

                var articles = data.articles;
                if (!articles || !articles.length) {
                    self.error_msg = articles['error'];
                    self.error = true;
                    self.update();
                } else {
                    riot.mount('gf-articles', {
                        articles: articles,
                        source: self.source,
                    });
                }
            });
        };


        self.setSource = function (code) {
            self.source = code;
            updateLanguage(self.source);
            self.sourceSelector.find('.selector-display').text($.uls.data.getAutonym(self.source));
        };

        self.onSelectSource = function (code) {
            self.setSource(code);
            self.origin = 'language_select';
            $('input[name=seedArticle]').val('');
            self.fetchArticles();
        };

        self.getSourceSelectorPosition = function () {
            var offset = self.sourceSelector.offset();
            return {
                top: offset.top + self.sourceSelector[0].offsetHeight,
                left: offset.left
            };
        };


        self.searchAPI = function (query) {
            var languageFilter = this;

            $.ajax({
                url: 'https://en.wikipedia.org/w/api.php',
                data: {
                    search: query,
                    format: 'json',
                    action: 'languagesearch'
                },
                dataType: 'jsonp',
                contentType: 'application/json'
            }).done(function (result) {
                $.each(result.languagesearch, function (code, name) {
                    if (languageFilter.resultCount === 0) {
                        languageFilter.autofill(code, name);
                    }
                    if (languageFilter.render(code)) {
                        languageFilter.resultCount++;
                    }
                });
                languageFilter.resultHandler(query);
            });
        };

        self.activateULS = function (selector, onSelect, getPosition, languages) {
            selector.uls({
                onSelect: onSelect,
                onReady: function () {
                    self.uls.push(this);
                    this.position = getPosition;
                },
                languages: languages,
                searchAPI: true, // this is set to true to simply trigger our hacky searchAPI
                compact: true,
                menuWidth: 'medium'
            });
        };

        self.on('mount', function () {
            // build language list with names from uls for the codes passed in to languagePairs
            window.translationAppGlobals.languagePairs['source'].forEach(function (code) {
                self.sourceLanguages[code] = $.uls.data.getAutonym(code);
            });
            

            // Use a more flushed out ajax call to wikipedia's api
            // Otherwise, CORS stops the request
            $.fn.languagefilter.Constructor.prototype.searchAPI = self.searchAPI;

            // build the selectors using the language lists
            self.sourceSelector = $('a[name=from]');
            self.activateULS(self.sourceSelector, self.onSelectSource, self.getSourceSelectorPosition, self.sourceLanguages);

            // hide the selectors if the window resizes with a timeout
            var resizeTimer;
            $(window).resize(function () {
                clearTimeout(resizeTimer);
                resizeTimer = setTimeout(function () {
                    $.each(self.uls, function (index, item) {
                        item.hide();
                    });
                }, 50);
            });

            self.populateDefaults(self.sourceLanguages);

            if (self.source) {
                self.fetchArticles();
            }

            //search feedback/suggestion
            self.suggestSearches();
        });

        self.suggestSearches = function () {
            //TODO:
            //    1. not sure why adding id attribute in the text input field breaks things
            //    2. using addEvent below. Could have used jquery.
            var callbackOnSelect = function(event, val) {
                $('input[name=seedArticle]').val(val.title);
                self.fetchArticles();
            };

            var typeAhead = new WMTypeAhead('#seed-container', 'input[name=seedArticle]', callbackOnSelect);
            addEvent($('input[name=seedArticle]')[0], 'input',  function(){
                typeAhead.query(this.value, self.source);
            });
        };

        self.populateDefaults = function (sourceLanguages) {
            if (window.translationAppGlobals.s in sourceLanguages) {
                self.setSource(window.translationAppGlobals.s);
                self.origin = 'url_parameters';
            }

            var browserLanguages = navigator.languages || [ navigator.language || navigator.userLanguage ];
            browserLanguages = browserLanguages.filter(function (language) {
                return language in sourceLanguages;
            });

            if (!self.source) {
                var index = Math.floor(Math.random() * browserLanguages.length);
                self.setSource(browserLanguages[index]);
                self.origin = 'browser_settings';
                // remove option from the list of languages
                // this is not exactly the desired behavior, since the list is filtered based on the sourceLanguages
                // and this leaves the possibility for a populated target language to not be valid; however, since
                // currently the source and target language lists are the same, this works
                // TODO: remove hack described above
                browserLanguages.splice(index, 1);
            }

            $('input[name=seedArticle]').val(window.translationAppGlobals.seed);
        };

    </script>
</gf-input>