using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Agilis.ECommerce.Interfaces;
using Agilis.ECommerce.Mvc.Web.ViewModels.Store;
using Agilis.ECommerce.Data;
using AutoMapper;
using Microsoft.Practices.Unity;
using Agilis.ECommerce.Mvc.Web.ViewModels.Content;
using System.Configuration;
using System.Text.RegularExpressions;
using WebApplication1;
using WebApplication1.App_Start;

namespace Agilis.ECommerce.Mvc.Web.ViewModels.Common
{
    public class MasterLayoutViewModel
    {
        private ISpecialOfferRepository specialOfferRepository = UnityConfig.GetConfiguredContainer().Resolve<ISpecialOfferRepository>();
        private ICategoryRepository categoryRepository = UnityConfig.GetConfiguredContainer().Resolve<ICategoryRepository>();
        private IContentRepository contentRepository = UnityConfig.GetConfiguredContainer().Resolve<IContentRepository>();
        private IProductRepository productRepository = UnityConfig.GetConfiguredContainer().Resolve<IProductRepository>();
        private IAttributeItemRepository aiRepository = UnityConfig.GetConfiguredContainer().Resolve<IAttributeItemRepository>();
        private IBrandRepository brandRepository = UnityConfig.GetConfiguredContainer().Resolve<IBrandRepository>();
        private CategoryViewModel currentCategory;
        private List<AttributeViewModel> applicableAttributes;
        private List<BrandViewModel> brandAttributes;

        public string Domain
        {
            get
            {
                return ConfigurationManager.AppSettings["DomainName"].ToString();
            }
        }

        public virtual Quote Quote
        {
            get; set;
        }

        public List<AttributeViewModel> ApplicableAttributes
        {
            get { return applicableAttributes; }
            set { applicableAttributes = value; }
        }

        public MasterLayoutViewModel()
        {
            brandAttributes = new List<BrandViewModel>();
            ApplicableAttributeItems = new List<AttributeItem>();
            RangeAttributes = new List<AttributeItemViewModel>();
            Ranges = new List<AttributeItemViewModel>();
            Subcategories = new List<CategoryViewModel>();
            ApplicablePages = new List<ContentViewModel>();
            List<SpecialOffer> offers = specialOfferRepository.GetSpecialOffers();
            List<SpecialOfferViewModel> offerViewModels = Mapper.Map<List<SpecialOffer>, List<SpecialOfferViewModel>>(offers);
            SpecialOffers = offerViewModels.GroupBy(o => o.DisplayIndex).ToList();

            List<Category> topCategories = categoryRepository.GetTopLevelCategories();
            TopLevelCategories = Mapper.Map<List<Category>, List<CategoryViewModel>>(topCategories);
            foreach (CategoryViewModel viewModel in TopLevelCategories)
            {
                viewModel.SubCategories = Mapper.Map<List<Category>, List<CategoryViewModel>>(categoryRepository.GetSubCategories(viewModel.CategoryId));
            }
            SubMenuCategories = new List<CategoryViewModel>();
            applicableAttributes = new List<AttributeViewModel>();
            RecentlyViewedProducts = Mapper.Map<List<Product>, List<ProductViewModel>>(productRepository.GetRecentlyViewedProducts());
            GiftProducts = Mapper.Map<List<Product>, List<ProductViewModel>>(productRepository.GetGiftProducts());
            FeaturedProducts = Mapper.Map<List<Product>, List<ProductViewModel>>(productRepository.GetFavouriteProducts());
            LatestProducts = Mapper.Map<List<Product>, List<ProductViewModel>>(productRepository.GetLatestProducts());
            FooterContent = new FooterViewModel();
            FooterContent.LatestProducts = Mapper.Map<List<Product>, List<ProductViewModel>>(productRepository.GetLatestProducts());

            foreach (Category topCategory in topCategories)
            {
                RandomProductsViewModel randomProducts = new RandomProductsViewModel();
                randomProducts.Category = TopLevelCategories.Where(c => c.CategoryId == topCategory.CategoryId).SingleOrDefault();
                randomProducts.RandomProducts = Mapper.Map<List<Product>, List<ProductViewModel>>(productRepository.GetRandomProducts(topCategory));
                FooterContent.RandomProducts.Add(randomProducts);
            }

            CalculateBasketSummary();


            Brands = Mapper.Map<List<Brand>, List<BrandViewModel>>(brandRepository.Items);
            MenuViewModel = new MenuViewModel();
            MenuViewModel.Brands = brandRepository.Items; 
            MenuViewModel.Categories = TopLevelCategories;
            Quote = contentRepository.RetrieveRandomQuote();

            LiveProducts = productRepository.GetAllProducts().OrderBy(p => p.Name).Select(p => p.Name).ToList();
            LiveUrls = productRepository.GetAllProducts().OrderBy(p => p.Name).Select(p => "/products/" + p.Category.Url.ToLower() + "/p/" + p.Url.ToLower()).ToList();

            BannerText = contentRepository.GetContentByKey("data-banner-config").WebContent;

            Timer = contentRepository.GetContentByKey("data-banner-timer-config").WebContent;


        }

        public string BannerText
        {
            get; set;
        }


        public string Timer
        {
            get; set;
        }

        public string GetPageHeader()
        {
            if (ApplicableAttributeItems.Count == 1 && CurrentTopLevelCategory.CategoryId == 1)
            {
                if (ApplicableAttributeItems.Single().Attribute.DisplayName == "Colour" || ApplicableAttributeItems.Single().Attribute.DisplayName == "Size")
                {
                    return ApplicableAttributeItems.Single().DisplayName + " " + CurrentTopLevelCategory.Name + " for Gardens, Paths & Driveways";
                }
            }
            else
            {
                return currentCategory.PageTitle;
            }
            return null;
        }

        public string GetPageDescription()
        {
            if (ApplicableAttributeItems.Count == 1 && CurrentTopLevelCategory.CategoryId == 1)
            {
                if (ApplicableAttributeItems.Single().Attribute.DisplayName == "Colour" || ApplicableAttributeItems.Single().Attribute.DisplayName == "Size")
                {
                    return ApplicableAttributeItems.Single().Summary;
                }
            }
            return null;
        }

        public string GetPageTitle()
        {
            if (ApplicableAttributeItems.Count == 1 && CurrentTopLevelCategory.CategoryId == 1)
            {
                if (ApplicableAttributeItems.Single().Attribute.DisplayName == "Colour" || ApplicableAttributeItems.Single().Attribute.DisplayName == "Size")
                {
                    return ApplicableAttributeItems.Single().DisplayName + " " + CurrentTopLevelCategory.Name;
                }
            }
            return null;
        }

        public MenuViewModel MenuViewModel
        {
            get;
            set;

        }
        public bool ContainsMainAttribute
        {
            get;
            set;
        }


        public AttributeItemViewModel FirstAttributeItem
        {
            get
            {
                if (ApplicableAttributeItems.Count > 0)
                    return Mapper.Map<AttributeItem, AttributeItemViewModel>(ApplicableAttributeItems[0]);
                return null;
            }

        }

        public AttributeItemViewModel FirstNonBrandAttributeItem
        {
            get
            {
                if (ApplicableAttributeItems.Count > 1)
                {
                    AttributeItem item = ApplicableAttributeItems[0];
                    if (item.Attribute.Id != 207)
                    {
                        return Mapper.Map<AttributeItem, AttributeItemViewModel>(ApplicableAttributeItems[0]);
                    }
                    else
                    {
                        return Mapper.Map<AttributeItem, AttributeItemViewModel>(ApplicableAttributeItems[1]);
                    }

                }
                return null;
            }

        }
        public List<AttributeItemViewModel> Ranges
        {
            get;
            set;
        }

        public void CalculateBasketSummary()
        {
            Cart cart = Cart.GetCart(HttpContext.Current.Request.RequestContext.HttpContext);
            string summaryFormat = "{0} Items<br/>{1}";

            BasketSummary = string.Format(summaryFormat, cart.NumItems, cart.Total.ToString("c"));
            BasketTotal = cart.Total.ToString("c");
        }

        public string BasketSummary
        {
            get;
            set;
        }

        public string BasketTotal
        {
            get;
            set;
        }

        // Every product the new header's mega menu can show, loaded on first use so the menu reads the
        // product list once per page instead of once for every category and subcategory.
        private List<Product> menuProducts;

        // Visible products in a category for the new header's mega menu, in the category page's default order.
        public List<Product> GetMenuProducts(CategoryViewModel category)
        {
            if (menuProducts == null)
            {
                menuProducts = productRepository.GetAllProducts()
                    .Where(p => p.Category != null && p.Url != null)
                    .OrderByDescending(p => p.TaxRateID)
                    .ToList();
            }

            return menuProducts
                .Where(p => p.CategoryId == category.CategoryId)
                .GroupBy(p => p.Url)
                .Select(g => g.First())
                .ToList();
        }

        public static string GetMenuProductUrl(Product product)
        {
            return "/products/" + product.Category.Url.ToLower() + "/p/" + product.Url.ToLower();
        }

        // The "Ideal for: ..." heading that opens a category description on the old category pages, or null.
        public static string GetIdealFor(CategoryViewModel category)
        {
            if (string.IsNullOrWhiteSpace(category.Description))
            {
                return null;
            }

            Match match = Regex.Match(category.Description, @"<h2[^>]*>\s*Ideal for:?(.*?)</h2>", RegexOptions.IgnoreCase | RegexOptions.Singleline);
            if (!match.Success)
            {
                return null;
            }

            string text = Regex.Replace(match.Groups[1].Value, "<[^>]+>", " ");
            text = HttpUtility.HtmlDecode(Regex.Replace(text, @"\s+", " ")).Trim();
            return text.Length > 0 ? text : null;
        }

        public List<string> LiveProducts
        {
            get;
            set;
        }

        public List<string> LiveUrls
        {
            get;
            set;
        }

        public List<ProductViewModel> RecentlyViewedProducts
        {
            get;
            set;
        }
        public List<ProductViewModel> GiftProducts
        {
            get;
            set;
        }
        public List<ProductViewModel> FeaturedProducts
        {
            get;
            set;
        }
        public List<ProductViewModel> LatestProducts
        {
            get;
            set;
        }
        public FooterViewModel FooterContent
        {
            get;
            set;
        }

        public List<AttributeViewModel> FilterAttributes
        {
            get
            {
                return applicableAttributes;
            }
            set
            {
                applicableAttributes = value;
            }
        }

        public List<BrandViewModel> BrandAttributes
        {
            get
            {
                return brandAttributes;
            }
            set
            {
                brandAttributes = value;
            }
        }

        public List<BrandViewModel> Brands
        {
            get;
            set;
        }

        public bool IsTopLevelCategory
        {
            get;
            set;
        }

        public List<CategoryViewModel> Subcategories
        {
            get;
            set;
        }

        public List<ProductViewModel> SubCategoryProducts
        {
            get;
            set;
        }

        public List<AttributeItemViewModel> RangeAttributes
        {
            get;
            set;
        }

        public List<AttributeItem> ApplicableAttributeItems
        {
            get;
            set;
        }

        public List<ContentViewModel> ApplicablePages
        {
            get;
            set;
        }

        public int CurrentPage
        {
            get;
            set;
        }

        public bool ContainsBrandAttributes
        {
            get;
            set;
        }
        public bool ContainsRangeAttributes
        {
            get;
            set;
        }

        public List<AttributeItemViewModel> RelatedRanges
        {
            get;
            set;
        }

        public void SetCategoryProducts(int attributeItemId, List<Product> products)
        {
            List<int> ids = new List<int>();
            ids.Add(attributeItemId);
            if (Subcategories != null)
            {
                foreach (CategoryViewModel category in Subcategories)
                {
                    CategoryFilterInformation information = categoryRepository.GetNameAndDescription(category.CategoryId, ids);
                    if (information == null)
                    {
                        information = new CategoryFilterInformation();
                        information.Name = category.Name;
                        information.Description = category.Synopsis;
                    }
                    category.FilterInformation = information;
                    if (attributeItemId > 0)
                    {
                        category.FirstProduct = Mapper.Map<Product, ProductViewModel>(products.Where(p => p.CategoryId == category.CategoryId && p.AttributeItemIds.Contains(attributeItemId)).FirstOrDefault());
                    }
                    else
                    {
                        category.FirstProduct = Mapper.Map<Product, ProductViewModel>(products.Where(p => p.CategoryId == category.CategoryId).FirstOrDefault());
                    }

                }
            }
        }

        public void SetRangeProducts(List<Product> products, Category category)
        {
            if (Ranges != null)
            {
                foreach (AttributeItemViewModel item in Ranges)
                {
                    List<int> ids = new List<int>();
                    ids.Add(item.Id);
                    item.FilterInformation = categoryRepository.GetNameAndDescription(category.CategoryId, ids);
                    if (item.FilterInformation == null)
                    {
                        item.FilterInformation = new CategoryFilterInformation();
                        item.FilterInformation.Name = item.DisplayName;
                        item.FilterInformation.Description = item.Summary;
                    }
                    item.FirstProduct = Mapper.Map<Product, ProductViewModel>(products.Where(p => p.AttributeItemIds.Contains(item.Id)).FirstOrDefault());
                }
            }
        }
        public void SetFilterAttributeItems(List<AttributeItem> applicableAttributeItems)
        {
            List<AttributeViewModel> attributeViewModels = new List<AttributeViewModel>();
            IEnumerable<IGrouping<int, AttributeItem>> groupings = applicableAttributeItems.Where(ai => ai != null && ai.Attribute != null).GroupBy(ai => ai.Attribute.Id);
            List<int> brandAttributes = aiRepository.Items.Where(ai => ai.ExtraRelatedAttributeId > 0).Select(ai => ai.ExtraRelatedAttributeId.Value).ToList();
            foreach (IGrouping<int, AttributeItem> group in groupings)
            {
                AttributeViewModel attributeViewModel = Mapper.Map<Data.Attribute, AttributeViewModel>(applicableAttributeItems.First(ai => ai.Attribute.Id == group.Key).Attribute);
                if (!brandAttributes.Contains(attributeViewModel.Id))
                {
                    foreach (AttributeItem item in group)
                    {
                        AttributeItemViewModel itemViewModel = Mapper.Map<AttributeItem, AttributeItemViewModel>(item);
                        itemViewModel.Attribute = attributeViewModel;
                        attributeViewModel.AttributeItems.Add(itemViewModel);
                    }
                    attributeViewModels.Add(attributeViewModel);
                }

            }

            applicableAttributes = attributeViewModels;
        }

        public CategoryViewModel CurrentTopLevelCategory
        {
            get
            {
                return currentCategory;
            }
            set
            {
                currentCategory = value;
                if (currentCategory != null)
                {
                    SubMenuCategories = Mapper.Map<List<Category>, List<CategoryViewModel>>(categoryRepository.GetSubMenuCategories(currentCategory.CategoryId));
                }
            }
        }

        public List<IGrouping<int, SpecialOfferViewModel>> SpecialOffers
        {
            get;
            set;
        }

        public List<CategoryViewModel> TopLevelCategories
        {
            get;
            set;
        }

        public List<NewsArticleViewModel> LatestNewsArticles
        {
            get;
            set;
        }

        public List<CategoryViewModel> SubMenuCategories
        {
            get;
            set;
        }

        public void RemoveMainFilterAttributes()
        {
            if (CurrentTopLevelCategory.RangeFilters != null)
            {
                List<AttributeViewModel> attributestoremove = FilterAttributes.Where(a => CurrentTopLevelCategory.RangeFilters.Split(',').Contains(a.Id.ToString())).ToList();
                List<AttributeViewModel> newlist = new List<AttributeViewModel>();
                newlist.AddRange(FilterAttributes.Where(a => !attributestoremove.Contains(a)));
                FilterAttributes = newlist;
            }
        }


        public void RemoveBrandFilterAttribute()
        {
            //List<AttributeViewModel> attributestoremove = FilterAttributes.Where(a => CurrentTopLevelCategory.RangeFilters.Split(',').Contains(a.Id.ToString())).ToList();
            //List<AttributeViewModel> newlist = new List<AttributeViewModel>();
            //newlist.AddRange(FilterAttributes.Where(a => !attributestoremove.Contains(a)));
            //FilterAttributes = newlist;

            FilterAttributes.Remove(FilterAttributes.Where(a => a.Id == 207).Single());
        }

        public void AddRelatedRangeAttributes()
        {
            List<AttributeViewModel> attributes = new List<AttributeViewModel>();
            AttributeViewModel attrib = Mapper.Map<Data.Attribute, AttributeViewModel>(ApplicableAttributeItems.Where(ai => ai.Attribute.Id != 207).First().Attribute);
            attrib.IsVisible = true;
            List<AttributeItemViewModel> items = Mapper.Map<List<AttributeItem>, List<AttributeItemViewModel>>(aiRepository.Items.Where(i => i.Attribute.Id == attrib.Id).ToList());
            attrib.AttributeItems = items;
            attributes.Add(attrib);

            FilterAttributes = attributes;
        }
    }
}