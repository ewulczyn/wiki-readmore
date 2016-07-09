<gf-preview>
    <div id="previewModal" class="modal fade" role="dialog" tabindex="-1">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <div class="container-fluid">
                        <div class="row">
                            <h4 class="modal-title col-xs-8">{title}</h4>
                            <button type="button" class="btn btn-secondary borderless pull-xs-right col-xs-1" data-dismiss="modal"
                                    title="{$.i18n('modal-close')}">
                                <h4 class="m-y-0">&#x274c;</h4>
                            </button>
                            <a role="button" class="btn btn-secondary borderless pull-xs-right col-xs-1" target="_blank" href={articleLink}
                               title="{$.i18n('modal-new-window')}">
                                <h4 class="m-y-0">&#x2197;</h4>
                            </a>
                        </div>
                    </div>

                </div>
                <div class="modal-body">
                    <div class="embed-responsive embed-responsive-4by3">
                        <iframe id="previewDiv"></iframe>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" onclick={left}
                            class={btn: true, btn-secondary: true, borderless: true, pull-xs-left: true,
                            disabled: showIndex === 0}
                            title="{$.i18n('modal-previous')}">
                        <h4 class="m-y-0"><</h4>
                    </button>
                    <div class="dropdown-menu dropdown-menu-left">
                        <button type="button" class="dropdown-item" onclick={addToPersonalBlacklist}>
                            {$.i18n('article-flag-not-interesting')}
                        </button>
                        <button type="button" class="dropdown-item" onclick={addToGlobalBlacklist}>
                            {$.i18n('article-flag-not-notable', opts.to)}
                        </button>
                    </div>
                    <button type="button" onclick={right}
                            class={btn: true, btn-secondary: true, borderless: true, pull-xs-left: true,
                            disabled: showIndex > (articles.length - 2)}
                            title="{$.i18n('modal-next')}">
                        <h4 class="m-y-0">></h4>
                    </button>
                </div>
            </div>
        </div>
    </div>


    <script>
        var self = this;

        self.articles = opts.articles || [];
        self.title = opts.title || '';
        self.to = opts.to;
        self.from = opts.from;
        self.translateRoot = '//' + opts.from + '.wikipedia.org/wiki/Special:ContentTranslation?' +
            'from=' + opts.from +
            '&to=' + opts.to +
            '&campaign=' + translationAppGlobals.campaign;
        self.articleRoot = '//' + opts.from + '.wikipedia.org/wiki/';
        self.isSrcDocSupported = document.createElement('iframe').srcdoc !== undefined;

        self.index = -1;
        for (var i=0; i<self.articles.length; i++) {
            if (self.articles[i].title === self.title) {
                self.showIndex = i;
                break;
            }
        }

        var previewRoot = 'https://' + opts.from + '.wikipedia.org/api/rest_v1/page/html/';

        self.show = function () {
            var showing = self.articles[self.showIndex];
            self.title = showing.title;
            self.translateLink = self.translateRoot + '&page=' + showing.linkTitle;
            self.articleLink = self.articleRoot + showing.linkTitle;
            self.previewUrl = previewRoot + showing.linkTitle;

            self.showPreview('Loading...');

            $.get(self.previewUrl).done(function (data) {
                // Make all links in preview (1) work and (2) open in new window
                // This depends on the string below appearing in the html returned from the rest endpoint
                // More complex manipulation may be needed if this breaks
                data = data.replace('<base href="', '<base target="_blank" href="https:');
                // Get rid of some of the undesirable mediawiki styles
                data = data.replace('</head>', '<style type="text/css">.mw-body {margin: 0; border: none; padding: 0;}</style></head>');
                self.showPreview(data);
            }).fail(function (data) {
                self.showPreview($.i18n('modal-preview-fail'));
            });
        };

        self.setPreviewContent = function (data) {
            var iframe = $('#previewDiv')[0];
            $(iframe).attr("srcdoc", data);
            if (!self.isSrcDocSupported) {
                // This is needed to get the iframe content to load in IE, since srcdoc isn't supported yet
                // Found at github.com/jugglinmike/srcdoc-polyfill
                var jsUrl = "javascript: window.frameElement.getAttribute('srcdoc');"
                $(iframe).attr("src", jsUrl);
                iframe.contentWindow.location = jsUrl;
            }
        };

        self.showPreview = function (data) {
            $('#previewModal').on('shown.bs.modal', function (e) {
                // Necessary for Firefox, which has problems reloading the iframe
                self.setPreviewContent(data);
            });

            self.setPreviewContent(data);
            $('#previewModal').modal('show');

            self.update();
        };


        left () {
            if (self.showIndex > 0) {
                self.showIndex --;
                self.show();
            }
        }

        right () {
            if (self.showIndex < self.articles.length - 1) {
                self.showIndex ++;
                self.show();
            }
        }


        $('#previewModal').on('hide.bs.modal', function (e) {
            self.setPreviewContent('');
        });

        self.on('mount', function () {
            if (isFinite(self.showIndex)) {
                self.show();
            }
        });
    </script>

</gf-preview>
