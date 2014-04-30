<%@ page language="C#" autoeventwireup="true" codebehind="default.aspx.cs" inherits="Adaptive.ReactiveTrader.Web._default" %>

<!DOCTYPE html>

<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>Adaptive's Reactive Trader</title>
    <link rel="icon" type="image/ico" href="favicon.ico">

    <link rel="stylesheet" href="app.css" type="text/css" />

    <script src="//code.jquery.com/jquery-2.1.0.min.js"></script>
    <script src="//ajax.aspnetcdn.com/ajax/signalr/jquery.signalr-2.0.2.min.js"></script>
    <script src="//code.jquery.com/color/jquery.color-2.1.0.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/rxjs/2.2.20/rx.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/rxjs/2.2.20/rx.binding.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/rxjs/2.2.20/rx.time.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/knockout/3.1.0/knockout-min.js"></script>
    <script src="generated.js"></script>

    <!-- Google Analytics -->
    <script>
        (function (i, s, o, g, r, a, m) {
            i['GoogleAnalyticsObject'] = r; i[r] = i[r] || function () {
                (i[r].q = i[r].q || []).push(arguments)
            }, i[r].l = 1 * new Date(); a = s.createElement(o),
            m = s.getElementsByTagName(o)[0]; a.async = 1; a.src = g; m.parentNode.insertBefore(a, m)
        })(window, document, 'script', '//www.google-analytics.com/analytics.js', 'ga');

        ga('create', 'UA-46320965-2', 'reactivetrader.azurewebsites.net');
        ga('send', 'pageview');
    </script>

    <!-- ONE WAY PRICE TEMPLATE -->
    <script type="text/html" id="one-way=price-template">
        <table data-bind="click: onExecute">
            <tr>
                <td class="direction" data-bind="text: direction"></td>
            </tr>
            <tr>
                <td class="price">
                    <span data-bind="text: bigFigures"></span>
                    <span data-bind="text: pips" class="pips" ></span>
                    <span data-bind="text: tenthOfPips"></span>
                </td>
            </tr>
        </table>
    </script>

    <!-- SPOT TILE TEMPLATE -->
    <script type="text/html" id="spot-tile-template">
        <li id="tile" style="padding: 12px 15px" data-bind="css: { 'error-tile': state() == 2 || (state() == 0 && pricing().isStale()), 'normal-tile': !(state() == 2 || (state() == 0 && pricing().isStale())) }">
            <div data-bind="if: state() == 0">
                <div data-bind="template: { name: 'pricing-template', data: pricing }"></div>
            </div>
            <div data-bind="if: state() == 1">
                <div data-bind="template: { name: 'affirmation-template', data: affirmation }"></div>
            </div>
            <div data-bind="if: state() == 2">
                <div data-bind="template: { name: 'error-template', data: error }"></div>
            </div>
            <div data-bind="if: state() == 3">
                <div data-bind="template: { name: 'config-template', data: config }"></div>
            </div>
        </li>
    </script>

    <!-- AFFIRMATION TILE TEMPLATE -->
    <script type="text/html" id="affirmation-template">
        <table class="result-table">
            <tr>
                <td>
                    <span data-bind="text: currencyPair" class="tile-symbol"></span>
                    <span data-bind="if: rejected" class="tile-symbol rejected">REJECTED</span>
                </td>
            </tr>
            <tr>
                <td class="affirmation-details">
                    <span class="affirmation-price" data-bind="css: { 'rejected': rejected }">
                        <span data-bind="text: direction" class="secondary-foreground"></span>
                        <span data-bind="text: dealtCurrency" class="primary-foreground"></span>
                        <span data-bind="text: notional" class="primary-foreground"></span>
                        <br />
                        <span class="secondary-foreground">vs</span>
                        <span data-bind="text: otherCurrency" class="primary-foreground"></span>
                        <span class="secondary-foreground">at</span>
                        <span data-bind="text: spotRate" class="primary-foreground"></span>
                    </span>
                    <br />
                    <span class="secondary-foreground">Spot</span>
                    <span data-bind="text: valueDate" class="primary-foreground"></span>
                    <br />
                    <span class="secondary-foreground">Trade ID</span>
                    <span data-bind="text: tradeId" class="primary-foreground"></span>
                </td>
            </tr>
            <tr>
                <td>
                    <a href="javascript:void(0)" data-bind="click: dismiss">Done</a>
                </td>
            </tr>
        </table>
    </script>

    <!-- ERROR TILE TEMPLATE -->
    <script type="text/html" id="error-template">
        <table class="result-table">
            <tr>
                <td class="tile-symbol">Error</td>
            </tr>
            <tr>
                <td style="font-size: 16px">
                    <span style="color: #e8c0bb" data-bind="text: errorMessage" class="secondary-foreground"></span>
                </td>
            </tr>
            <tr style="height: 20px;">
                <td>
                    <a style="color: white;" href="javascript:void(0)" data-bind="click: dismiss">Done</a>
                </td>
            </tr>
        </table>
    </script>

    <!-- CONFIG TILE TEMPLATE -->
    <script type="text/html" id="config-template">
        CONFIG
    </script>

    <!-- PRICING TILE TEMPLATE -->
    <script type="text/html" id="pricing-template">
        <table style="height: 100%;">
            <tr>
                <td data-bind="text: symbol" class="tile-symbol"></td>
                <td data-bind="if: isExecuting" class="tile-symbol">EXECUTING</td>
            </tr>
            <tr>
                <td colspan="2">
                    <table style="text-align: center" data-bind="if: !isStale()">
                        <tr>
                            <td class="one-way-price">
                                <div data-bind="template: { name: 'one-way=price-template', data: bid }"></div>
                            </td>
                            <td style="width: 20px;">
                                <table style="height: 100%">
                                    <tr style="height: 30%">
                                        <td>
                                            <div class="arrow-up" data-bind="visible: movement() === 2"></div>
                                        </td>
                                    </tr>
                                    <tr style="height: 40%">
                                        <td><span data-bind="text: spread" class="primary-foreground" style="font-size: 16px; margin: 3px"></span></td>
                                    </tr>
                                    <tr style="height: 30%">
                                        <td>
                                            <div class="arrow-down" data-bind="visible: movement() === 1"></div>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                            <td class="one-way-price">
                                <div data-bind="template: { name: 'one-way=price-template', data: ask }"></div>
                            </td>
                        </tr>
                    </table>
                    <div style="color: white; text-align: left" data-bind="if: isStale()">Pricing currently unavailable</div>
                </td>
            </tr>
            <tr data-bind="if: !isStale()">
                <td>
                    <span data-bind="text: dealtCurrency" class="secondary-foreground" style="font-size: 16px"></span>
                    <input data-bind="value: notional" class="notional" style="font-size: 16px" />
                </td>
                <td><span data-bind="text: spotDate" class="secondary-foreground" style="font-size: 16px; float: right;"></span></td>
            </tr>
        </table>
    </script>
</head>

<body>

    <div id="tiles-area" data-bind="if: !sessionExpired()">
        <a id="githubBanner" href="https://github.com/AdaptiveConsulting/ReactiveTrader">
            <img src="https://camo.githubusercontent.com/52760788cde945287fbb584134c4cbc2bc36f904/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f77686974655f6666666666662e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_white_ffffff.png">
        </a>

        <ul class="tile" data-bind="template: { name: 'spot-tile-template', foreach: spotTiles.spotTiles }"></ul>
    </div>

    <div id="session-expired-area" data-bind="visible: sessionExpired">
        Your 15 minutes session expired, you are now disconnected from the server. Click reconnect to start a new session.<br />
        <i></i>
        <a id="reconnect-link" href="javascript:void(0)" data-bind="click: reconnect">Reconnect</a>
    </div>

    <div id="blotter-area">
        <table>
            <thead>
                <tr>
                    <th id="dateHeader">Date</th>
                    <th id="dirHeader">Dir.</th>
                    <th id="ccyHeader">CCY</th>
                    <th id="notionalHeader">Notional</th>
                    <th id="rateHeader">Rate</th>
                    <th id="statusHeader">Status</th>
                    <th id="valueDateHeader">Value Date</th>
                    <th id="traderHeader">Trader</th>
                </tr>
            </thead>
            <tbody data-bind="foreach: { data: blotter.trades, afterAdd: fadeTrade }">
                <tr data-bind="css: { rejected: tradeStatus == 'REJECTED' }">
                    <td data-bind="text: tradeDate"></td>
                    <td data-bind="text: direction" class="text-center"></td>
                    <td data-bind="text: currencyPair"></td>
                    <td data-bind="text: notional" class="text-right"></td>
                    <td data-bind="text: spotRate" class="text-right"></td>
                    <td data-bind="text: tradeStatus" class="tradeStatus"></td>
                    <td data-bind="text: valueDate" class="text-center"></td>
                    <td data-bind="text: traderName"></td>
                </tr>
            </tbody>
        </table>
    </div>
    <div id="status-bar-area">
        <table data-bind="css: { disconnected: connectivityStatus.disconnected() }">
            <tr>
                <td>
                    <span data-bind="text: connectivityStatus.status"></span>
                    <span data-bind="visible: !connectivityStatus.disconnected()">| UI Upd.:</span>
                    <span data-bind="text: connectivityStatus.uiUpdates, visible: !connectivityStatus.disconnected()"></span>
                    <span data-bind="visible: !connectivityStatus.disconnected()">/sec | Server Upd.:</span>
                    <span data-bind="text: connectivityStatus.ticksReceived, visible: !connectivityStatus.disconnected()"></span>
                    <span data-bind="visible: !connectivityStatus.disconnected()">/sec | UI Lat.:</span>
                    <span data-bind="text: connectivityStatus.uiLatency, visible: !connectivityStatus.disconnected()"></span>
                    <span data-bind="visible: !connectivityStatus.disconnected()">ms</span>
                </td>

                <td id="weAreAdaptiveCell">
                    <a href="http://www.weareadaptive.com" target="_blank">
                        <img alt="We Are Adaptive" src="statusbar_logo.png" /></a>
                </td>
            </tr>
        </table>
    </div>

</body>
</html>

