import { describe, expect, it } from "vitest";

describe("Stripe server configuration", () => {
  it("accepts only server-side test/live secret formats when configured", () => {
    const secret = process.env.MIRROR_STRIPE_SECRET_KEY;
    const webhook = process.env.MIRROR_STRIPE_WEBHOOK_SECRET;
    const monthlyPrice = process.env.MIRROR_STRIPE_PRO_MONTHLY_PRICE_ID;
    const yearlyPrice = process.env.MIRROR_STRIPE_PRO_YEARLY_PRICE_ID;

    if (secret) expect(secret).toMatch(/^sk_(test|live)_/);
    if (webhook) expect(webhook).toMatch(/^whsec_/);
    if (monthlyPrice) expect(monthlyPrice).toMatch(/^price_/);
    if (yearlyPrice) expect(yearlyPrice).toMatch(/^price_/);
    expect("MIRROR_STRIPE_SECRET_KEY").not.toMatch(/VITE_/);
  });
});
