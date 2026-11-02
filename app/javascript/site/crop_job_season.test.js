import { beforeEach, describe, expect, it } from 'vitest';
import { describeDay, initCropJobSeason } from './crop_job_season';

const seasons = [{ name: 'Tomato jobs', season: 'spring and summer', months: [9, 10, 11, 12, 1, 2] }];

describe('initCropJobSeason', () => {
  let field;
  let warning;
  let confirm;
  let submit;

  const pick = (value) => {
    field.value = value;
    field.dispatchEvent(new Event('input'));
  };

  beforeEach(() => {
    document.body.innerHTML = `
      <form data-crop-job-seasons='${JSON.stringify(seasons)}'
            data-crop-job-warning-text="%{template} is for %{season}, and %{date} is outside that.">
        <input type="date" data-crop-job-date value="2026-11-07">
        <small data-crop-job-when></small>
        <div data-crop-job-warning hidden></div>
        <input type="hidden" data-crop-job-confirm disabled>
        <input type="submit" data-crop-job-submit value="Add these jobs"
               data-label="Add these jobs" data-anyway-label="Add them anyway">
      </form>`;
    field = document.querySelector('[data-crop-job-date]');
    warning = document.querySelector('[data-crop-job-warning]');
    confirm = document.querySelector('[data-crop-job-confirm]');
    submit = document.querySelector('[data-crop-job-submit]');
    initCropJobSeason();
  });

  it('says nothing for a day in the season', () => {
    expect(warning.hidden).toBe(true);
  });

  it('warns for a day outside the season', () => {
    pick('2026-06-13');
    expect(warning.textContent).toContain('Tomato jobs is for spring and summer');
  });

  it('shows the warning once the day is outside the season', () => {
    pick('2026-06-13');
    expect(warning.hidden).toBe(false);
  });

  it('sends that they agreed once the day is outside the season', () => {
    pick('2026-06-13');
    expect(confirm.disabled).toBe(false);
  });

  it('offers to add them anyway', () => {
    pick('2026-06-13');
    expect(submit.value).toBe('Add them anyway');
  });

  it('goes back to the plain button when the day is back in season', () => {
    pick('2026-06-13');
    pick('2026-10-10');
    expect(submit.value).toBe('Add these jobs');
  });
});

describe('describeDay', () => {
  const today = new Date(2026, 10, 1);

  it('names the day of the week', () => {
    expect(describeDay('2026-11-07', today)).toMatch(/^Saturday/);
  });

  it('counts days when it is soon', () => {
    expect(describeDay('2026-11-07', today)).toContain('in 6 days');
  });

  it('says tomorrow', () => {
    expect(describeDay('2026-11-02', today)).toContain('tomorrow');
  });

  it('counts weeks when it is further off', () => {
    expect(describeDay('2026-11-28', today)).toContain('in 4 weeks');
  });

  it('counts months when it is further still', () => {
    expect(describeDay('2027-03-06', today)).toContain('in 4 months');
  });
});
