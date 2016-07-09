<gf-title>
    <div class="container-fluid m-t-1">
        <div class="row">
            <div class="dropdown">
                <div class="col-xs-12">
                    <span class="icon icon-title icon-lightbulb"></span>
                    <span class="title-display" data-i18n="title-wikipedia">Wikipedia</span>
                    <span class="title-display-strong">ReadMore</span>
                    <span class="title-display-version" data-i18n="title-beta">beta</span>
                    <span class="icon icon-title icon-menu dropdown-toggle"
                          data-toggle="dropdown"></span>
                    <div class="dropdown-menu dropdown-menu-right m-r-1">
                        <button class="dropdown-item" type="button"
                                data-toggle="modal" data-target="#howToModal" data-i18n="menu-how-to">How to</button>
                        <button class="dropdown-item" type="button"
                                data-toggle="modal" data-target="#aboutModal" data-i18n="menu-about">About</button>
                        <a class="dropdown-item" href="https://github.com/ewulczyn/wiki-readmore"
                           target="_blank" data-i18n="menu-source-code">Source code</a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="howToModal" class="modal fade" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">
                        <h4 class="modal-title">&#x274c;</h4>
                    </button>
                    <h4 class="modal-title" data-i18n="menu-how-to">How to</h4>
                </div>
                <div class="modal-body">
                    <p>ReadMore helps you discover interesting articles to read on Wikipedia.

                    <p>Start by selecting your language. Readmore will find articles that are currently trending.

                    <p>If you are interested in a particular topic area, provide a seed article and ReadMore will give you a list of articles that other people tend to read in the same session.

                    <p>Click on a card to start reading
                </div>
            </div>
        </div>
    </div>

    <div id="aboutModal" class="modal fade" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">
                        <h4 class="modal-title">&#x274c;</h4>
                    </button>
                    <h4 class="modal-title" data-i18n="menu-about">About</h4>
                </div>
                <div class="modal-body">
                    <p>ReadMore's search is based on a semantic embedding of Wikipedia articles.
                </div>
            </div>
        </div>
    </div>
</gf-title>
