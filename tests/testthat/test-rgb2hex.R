context('rgb2hex')

test_that('rgb2hex returns correct HEX from RGB', {
  expect_equal(rgb2hex('255,195,77'), '#FFC34D') # ignore.case = TRUE
})
