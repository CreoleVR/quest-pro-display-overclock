#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/moduleparam.h>
#include "dsi_display.h"

static unsigned int get_disp_hi;
static unsigned int get_disp_lo;
static int dry_run;
module_param(get_disp_hi, uint, 0444);
MODULE_PARM_DESC(get_disp_hi, "hi32 of dsi_display_get_active_displays addr");
module_param(get_disp_lo, uint, 0444);
module_param(dry_run, int, 0444);
MODULE_PARM_DESC(dry_run, "1 = only read+log, do not modify");

static const u32 addrates[] = { 100, 110, 120, 144, 165 };
#define NADD ((u32)ARRAY_SIZE(addrates))

static u32 newlist[128];

static int __init qp_init(void)
{
	int (*get_active)(void **, u32);
	void *arr[8];
	int n, i;
	struct dsi_display *disp = NULL;
	struct dsi_panel *panel;
	struct dsi_dfps_capabilities *dc;
	u32 oldlen, mult, k, newmax;
	unsigned long addr = ((unsigned long)get_disp_hi << 32) |
			     (unsigned long)get_disp_lo;

	if (!addr)
		return -EINVAL;
	get_active = (void *)addr;

	n = get_active(arr, 8);
	if (n <= 0)
		return -ENODEV;

	for (i = 0; i < n; i++) {
		struct dsi_display *d = arr[i];

		if (d && d->panel && d->panel->dfps_caps.dfps_support) {
			disp = d;
			break;
		}
	}
	if (!disp)
		return -ENODEV;

	panel = disp->panel;
	dc = &panel->dfps_caps;
	oldlen = dc->dfps_list_len;

	pr_info("qp_refresh165: type=%u len=%u min=%u max=%u modes=%u\n",
		dc->type, oldlen, dc->min_refresh_rate, dc->max_refresh_rate,
		panel->num_display_modes);

	if (dc->type == 0 || dc->type >= 5)
		return -EINVAL;
	if (oldlen < 8 || oldlen > 40)
		return -EINVAL;
	if (dc->max_refresh_rate < 60 || dc->max_refresh_rate > 96)
		return -EINVAL;
	if (dc->min_refresh_rate < 24 || dc->min_refresh_rate > dc->max_refresh_rate)
		return -EINVAL;
	if (!dc->dfps_list)
		return -EINVAL;
	if (panel->num_display_modes == 0 || (panel->num_display_modes % oldlen) != 0)
		return -EINVAL;

	mult = panel->num_display_modes / oldlen;
	if (mult == 0 || mult > 8)
		return -EINVAL;
	if (oldlen + NADD > ARRAY_SIZE(newlist))
		return -EINVAL;
	if (dry_run)
		return 0;

	for (k = 0; k < oldlen; k++)
		newlist[k] = dc->dfps_list[k];
	for (k = 0; k < NADD; k++)
		newlist[oldlen + k] = addrates[k];
	newmax = addrates[NADD - 1];

	dc->dfps_list = newlist;
	dc->dfps_list_len = oldlen + NADD;
	if (dc->max_refresh_rate < newmax)
		dc->max_refresh_rate = newmax;
	panel->num_display_modes += NADD * mult;
	disp->modes = NULL;

	pr_info("qp_refresh165: added 100/110/120/144/165Hz, max=%u list_len=%u num_modes=%u\n",
		dc->max_refresh_rate, dc->dfps_list_len, panel->num_display_modes);
	return 0;
}

module_init(qp_init);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("CreoleVR");
MODULE_DESCRIPTION("Append 100/110/120/144/165Hz to Quest Pro DSI dfps list");
