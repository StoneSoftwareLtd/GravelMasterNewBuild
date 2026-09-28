# The Track Order pop-up's answers in the preview (Views/Shared/_TrackOrderPopup.cshtml).
#
# The pop-up posts orderId and postcode to /checkout/checkmyorder, the site's order lookup (CheckoutController.CheckMyOrder).
# The preview never asks the live one, as it looks up real customers' orders. It answers for a few sample orders instead,
# the way the lookup on master does, with its sentences, so each kind of answer can be tried.

# Sample order number -> the lookup's answer for it. 123456 is the sample order confirmation's order and the sample
# customer's newest order; 118870 is the sample customer's older one (confirmation-page.ps1, myaccount-pages.ps1).
$script:sampleTrackOrders = [ordered]@{
  '123456' = 'Your order has been accepted and is now being processed by the team!'
  '123457' = 'Your goods have now left us and are with your local delivery depot who will be delivering your order on your selected delivery date!'
  '123458' = 'Your order is now on a delivery vehicle and will be with you today - ETA''s are currently not available <b>(Coming Soon).</b>'
  '118870' = 'Your goods have now been delivered! Not the case? Call us on <b>0330 0585068 option 2</b> to speak to a member of our team.'
}
# Every sample order is to the sample customer's address
$script:sampleTrackPostcode = 'NG7 2RD'

# For the pop-up in the preview: which numbers to try
$script:sampleTrackNote = '<p style="margin:0 0 16px;padding:8px 12px;background:#fff4d6;color:#4a3b00;border-radius:6px;font-size:13px;line-height:1.45">' +
  'Preview: sample orders, postcode ' + $script:sampleTrackPostcode + ': 123456 being prepared, 123457 at the depot, 123458 out for delivery, 118870 delivered. ' +
  'Any other number or postcode gets the lookup''s other answers.</p>'

# $body: the posted form, e.g. "orderId=123456&postcode=NG7+2RD". Gives what CheckMyOrder would send back.
function Get-SampleTrackAnswer([string]$body) {
  $fields = @{}
  foreach ($pair in $body.Split('&')) {
    $kv = $pair.Split('=', 2)
    if ($kv.Count -eq 2) { $fields[[Uri]::UnescapeDataString($kv[0].Replace('+', ' '))] = [Uri]::UnescapeDataString($kv[1].Replace('+', ' ')) }
  }
  $unavailable = 'The order tracking system is currently unavailable, please try again in a few minutes'
  # int.Parse(orderId), and postcode.Replace(...) with no postcode, throw: the lookup's catch gives $unavailable
  $number = 0
  if (-not [int]::TryParse([string]$fields['orderId'], [ref]$number)) { return $unavailable }
  $answer = $script:sampleTrackOrders[[string]$number]
  if (-not $answer) {
    return 'Your order details are currently unavailable, please check back for further details later or contact the team on 0300 0585068'
  }
  $postcode = $fields['postcode']
  if ($null -eq $postcode) { return $unavailable }
  if ($postcode.Replace(' ', '').ToLower() -ne $script:sampleTrackPostcode.Replace(' ', '').ToLower()) {
    # the lookup repeats the postcode as it was typed, unencoded
    return 'We have found the order, but the postcode is not: ' + $postcode
  }
  $answer
}
